#!/usr/bin/env ruby
# coding: utf-8
require "socket"
require "ipaddr"
require 'bindata'
require 'timeout'
# require "pry" # if you need

class Property2Hash
  def self.execute property
    ret = {}
    property.each do |val|
      epc =val.epc
      case epc
      when 0x80
        tmp = val.edt[0]
        ret[:power] = (tmp == 0x30)? true:false
      when 0xb0
        sw_val = val.edt[0]
        if sw_val == 0x41
          valstr = :automatic
        elsif sw_val == 0x42
           valstr = :cCooling
        elsif sw_val == 0x43
           valstr = :heating
        elsif sw_val == 0x44
           valstr =  :dehumidification
        elsif sw_val == 0x45
            valstr = :air_circulator
        elsif sw_val == 0x40
            valstr = :other
        else
            valstr = "unknown"
        end
        ret[:mode] = valstr
      when 0xb3
        val = val.edt[0]
        ret[:set_temperature]= val.to_i
      when 0xba
        val = val.edt[0]
        ret[:room_humidity]= val
      when 0xbb
        val = val.edt[0]
        if val > 127 then val = 256 - val end
        ret[:room_temperature]= val
      when 0xbe
        val = val.edt[0]
        if val == 0x7e then
          ret[:outside_temperature]= nil
          next
        end
        if val > 127 then val = 256 - val end
        ret[:outside_temperature]= val
      else
        ## nothing
      end ## end of case
    end  ## end of property each
    return ret
  end ## end of print_debug
end


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


class Airconditioner
  attr_reader :recv_data
  
  def initialize  arg_send_ip, arg_eoj
    @send_ip = arg_send_ip
    @target_eoj = arg_eoj
  end

  def get_status
    udps = UDPSocket.open()
    udps.bind("0.0.0.0",3610)
    mreq = IPAddr.new("224.0.23.0").hton + IPAddr.new("0.0.0.0").hton
    udps.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, mreq)

    tid =  rand(10000)
    send_get_status_data tid
    recv = recv_data_loop udps, tid
    udps.close

    return nil if recv == false
    data = @recv_data
    property = data[:edata][:property]
    ret =  Property2Hash.execute property
    return ret
  end

  def init_send
    seoj = BEOJ.new
    seoj.set_values 0x05,0xff,0x01
    @edata = EData.new
    @edata.set_values seoj,@target_eoj,EData::ESV_Set_Get
  end

  def send_command
    ip=@send_ip
    u = UDPSocket.new()
    u.connect(ip,3610)
    echonetdata = EchonetData.new
    echonetdata.set_val 0x1111,@edata
    p echonetdata.to_hex
    data=echonetdata.to_binary_s 
    data = data + "\x00"
    p data
    
    u.send(data ,0)
    u.close
  end
  
  def set_power power
    property = PropertyData.new
    property[:epc] = 0x80
    property[:pdc] = 0x01
    property[:edt][0] = (power)? 0x30:0x31
    @edata.add_property property
  end
  def set_temp temp
    property = PropertyData.new
    property[:epc] = 0xb3 # set temp
    property[:pdc] = 0x01
    property[:edt][0] = temp
    @edata.add_property property
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


  def send_get_status_data tid
    seoj = BEOJ.new
    seoj.set_values 0x05,0xff,0x01

    edata = EData.new
    edata.set_values seoj,@target_eoj,EData::ESV_INF_REQ
    command=%w( 0x80 0xb0 0xb3 0xba 0xbb 0xbe )
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

end



#aircon_eoj = BEOJ.new
#aircon_eoj.set_values 0x01,0x30,0x03
#a = Airconditioner.new("192.168.33.111",aircon_eoj)
#bb=a.get_status
#bb.each do |key,val|
#  puts "#{key} #{val}"
#end

