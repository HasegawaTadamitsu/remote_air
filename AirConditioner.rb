#!/usr/bin/env ruby

require "./Echonet.rb"

class AirConditioner 
  
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

  def set_temp temp
    property = PropertyData.new
    property[:epc] = 0xb3 # set temp
    property[:pdc] = 0x01
    property[:edt][0] = temp
   @property << property
  end

  def send
    @echonet_comminication.set_i @property
    @property= Array.new
  end

  def get_status
    property = @echonet_comminication.inf_req  %w( 0x80 0xb0 0xb3 0xba 0xbb 0xbe )
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
  end
end



aircon_eoj=[0x01,0x30,0x03]
a = AirConditioner.new("192.168.33.111",aircon_eoj)
bb=a.get_status
bb.each do |key,val|
  puts "#{key} #{val}"
end
a.set_power true
a.set_temp 25
#a.send


