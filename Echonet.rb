#!/usr/bin/env ruby
# coding: utf-8
require "socket"
require "ipaddr"
require 'bindata'
require 'timeout'


class PropertyData < BinData::Record
  uint8be  :epc  #Echonet lite  Property count
  uint8be  :pdc  #Property Data count
  array  :edt, :type => :uint8be,  :initial_length => :pdc
end

class BEOJ < BinData::Record
  uint8be  :class_group_code
  uint8be  :class_code
  uint8be  :instance_code
  def set_values a,b,c
    self[:class_group_code] = a
    self[:class_code] = b
    self[:instance_code] = c
  end
end

class EData < BinData::Record
  beoj  :seoj  #source Echonet lite ObJect 
  beoj  :deoj  #dest   Echonet lite ObJect 
  uint8be  :esv  #Echonet lite SerVice
  uint8be  :opc  #Object Property count
  array  :property, :type => :propertyData,  :initial_length => :opc

  ESV_Set_I = 0x60
  ESV_Set_C = 0x61
  ESV_INF_REQ = 0x63
  ESV_Set_Get = 0x6e
  
  def set_values a_seoj,a_deoj,a_esv
    self[:seoj] = a_seoj
    self[:deoj] = a_deoj
    self[:esv]  = a_esv
  end
  def add_property a_property
    before_opc = self[:opc]
    self[:property][before_opc] = a_property
    self[:opc] = before_opc + 1
  end
end

class EchonetData < BinData::Record
  uint8be  :ehd1 # Echonet lite denbun HeaDer1
  uint8be  :ehd2 # Echonet lite denbun HeaDer2
  uint16be :tid  # Trunsaction ID
  eData    :edata #Echonet lite data
  def set_val arg_tid, arg_edata
    self[:ehd1] = 0x10
    self[:ehd2] = 0x81
    self[:tid] = arg_tid
    self[:edata] = arg_edata
  end
end


class EchonetComminication
  attr_reader :recv_data
  
  def initialize  arg_send_ip, arg_eoj
    @send_ip = arg_send_ip
    eoj = BEOJ.new
    eoj.set_values arg_eoj[0],arg_eoj[1],arg_eoj[2]
    @target_eoj = eoj
  end

  def inf_req command
    udps = UDPSocket.open()
    udps.bind("0.0.0.0",3610)
    mreq = IPAddr.new("224.0.23.0").hton + IPAddr.new("0.0.0.0").hton
    udps.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, mreq)

    tid =  rand(10000)
    send_get_status_data tid, command
    recv = recv_data_loop udps, tid
    udps.close

    return nil if recv == false
    data = @recv_data
    property = data[:edata][:property]
    return property
  end

  def set_i arg_property
    seoj = BEOJ.new
    seoj.set_values 0x05,0xff,0x01
    @edata = EData.new
    @edata.set_values seoj,@target_eoj,EData::ESV_Set_I ## HMM! bad  ESV_Set_Get
    arg_property.each do |pro|
      @edata.add_property pro
    end
    u = UDPSocket.new()
    u.connect(@send_ip,3610)
    echonetdata = EchonetData.new
    echonetdata.set_val 0x1111,@edata
    data=echonetdata.to_binary_s  
    p data
    u.send(data ,0)
    u.close
  end

  
  private
  def send_get_status_data tid,command
    seoj = BEOJ.new
    seoj.set_values 0x05,0xff,0x01
    edata = EData.new
    edata.set_values seoj,@target_eoj,EData::ESV_INF_REQ
    command.each do | com |
      property = PropertyData.new
      property[:epc] = com.to_i(16)
      property[:pdc] = 0x00
      edata.add_property property
    end
    
    echonetdata = EchonetData.new
    echonetdata.set_val tid ,edata
    
    u = UDPSocket.new()
    u.connect(@send_ip,3610)
    # p echonetdata.to_hex
    u.send(echonetdata.to_binary_s,0)
    u.close
  end

  
  private
  def recv_data_loop udps,tid
    begin
      Timeout.timeout(5) do 
        3.times  do
          msg =  udps.recvmsg
          raw_data = msg[0]
          ip_addr = msg[1]
          @recv_data = EchonetData.read( raw_data )
          if  @recv_data[:tid] == tid and ip_addr.ip_address == @send_ip
            return true
          end
          puts  "recev other data #{ip_addr.ip_address},#{@recv_data[:tid]}"
        end # end of times loop
      end # timeout
    rescue Timeout::Error => e
        p 'main: timeout', e.backtrace.first
    end
    puts  "hmm data #{ip_addr.ip_address},#{@recv_data[:tid]}"
    return false         
  end

end



