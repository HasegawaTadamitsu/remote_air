#!/usr/bin/env ruby

require "./Echonet.rb"

class AirCleaner
  
  def initialize  arg_send_ip, arg_eoj
    @send_ip = arg_send_ip
    @target_eoj = arg_eoj
    @echonet_comminication = EchonetComminication.new @send_ip,@target_eoj
    @property= Array.new
  end

  def set_power power_flag
    property = PropertyData.new
    property[:epc] = 0x80
    property[:pdc] = 0x01
    property[:edt][0] = (power_flag)? 0x30:0x31
   @property << property
  end

  def send
    @echonet_comminication.set_i @property
    @property= Array.new
  end

  def get_status
    property = @echonet_comminication.inf_req %w( 0x80 0xa0 0xc0)
    ret = {}
    property.each do |val|
      epc =val.epc
      case epc
      when 0x80
        tmp = val.edt[0]
        ret[:power] = (tmp == 0x30)? true:false
      when 0xa0
        sw_val = val.edt[0]
        if sw_val == 0x41
           str =  "Automatic"
        else
          str =   sw_val
        end
        ret[:flowRate] =str 
      when 0xc0
        sw_val = val.edt[0]
        if sw_val == 0x41
          str = "detected"
        elsif sw_val == 0x42
          str = "non-detected"
        else
          str = "unknown status"
        end
        ret[:pollution] = str
      else
        ## nothing
      end ## end of case
    end  ## end of property each
    return ret
  end
end


aircon_eoj=[0x01,0x35,0x01]
a = AirCleaner.new("192.168.33.126",aircon_eoj)
bb=a.get_status
bb.each do |key,val|
  puts "#{key} #{val}"
end
#a.set_power true
a.send

