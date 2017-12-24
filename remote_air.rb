require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'
require 'sinatra/reloader'
require './Airconditioner.rb'

set :port, 4568
set :bind, '0.0.0.0'


STDOUT.sync = true
STDERR.sync = true

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end


get '/' do
  aircon_eoj_1F = BEOJ.new
  aircon_eoj_1F.set_values 0x01,0x30,0x04
  ac_1f = Airconditioner.new  "192.168.33.111",aircon_eoj_1F
  @aircon1f_status = ac_1f.get_status


  aircon_eoj_2F = BEOJ.new
  aircon_eoj_2F.set_values 0x01,0x30,0x03
  ac_2f = Airconditioner.new  "192.168.33.111",aircon_eoj_2F
  @aircon2f_status = ac_2f.get_status
  haml :index
end

post  '/aircon1f'  do
  aircon_eoj_1F = BEOJ.new
  aircon_eoj_1F.set_values 0x01,0x30,0x04
  ac_1f = Airconditioner.new  "192.168.33.111",aircon_eoj_1F
  ac_1f.init_send
  p params
  
  power= ( params[:power]=="true"?true:false)
p power                           
  ac_1f.set_power power
  if power
    val=params[:set_temperature].to_i
    p  val
    ac_1f.set_temp  val
  end
  ac_1f.send_command
  haml :ok
end

post  '/aircon2f'  do
  aircon_eoj_2F = BEOJ.new
  aircon_eoj_2F.set_values 0x01,0x30,0x03
  ac_2f = Airconditioner.new  "192.168.33.111",aircon_eoj_2F
  ac_2f.init_send
  p params
  
  power= ( params[:power]=="true"?true:false)
p power                                                      
  ac_2f.set_power power
  if power 
    val =params[:set_temperature].to_i
    p  val
    ac_2f.set_temp  val
  end
  ac_2f.send_command
  haml :ok
end

__END__

@@ style
h1
  margin-top: 1em
  font-size: 16px
  text-align: left

li
  font:
    size: 1em

contents
  margin: 2em,2em,2em,2em

@@ layout
!!! XML
!!! Strict

%html
  %head
    %title=@title 
    %meta{"http-equiv": "Content-Type", content: "text/html", |
          charset: "utf-8"}
    %meta{"http-equiv": "Pragma",       content: "no-cache"}
    %meta{"http-equiv": "Cache-Control",content: "no-cache"}
    %meta{"http-equiv": "Expires",      content: "-1"}
    %link{:rel=>"stylesheet", :type=>"text/css", :href=>"/style.css"}
  %body
    #contents
      != yield

@@ ok
%h1 remote air web
%h2 send command ok
%a{ href: '/' } jump to status 

@@ index
%h1 remote air web
%h2 1f
%form{ :action => "/aircon1f" , :method => "post" }
  %ul
    %li 
      Power
      #{@aircon1f_status[:power]}
      %select{ :name => 'power' }
        %option{ value: 'true'  , selected:   @aircon1f_status[:power]  } ON
        %option{ value: 'fasle' , selected: (!@aircon1f_status[:power]) } off
    %li
      Mode #{@aircon1f_status[:mode]}
    %li
      set temperature  #{@aircon1f_status[:set_temperature]} deg C to 
      %input{ :name=>'set_temperature', :type =>'number' ,:min=>'18' ,:max=>'30',:value=>@aircon1f_status[:set_temperature] } deg C
    %li
      room_humidity  #{@aircon1f_status[:room_humidity]} %
    %li
      room_temperature  #{@aircon1f_status[:room_temperature]} deg C
    %li
      outside_temperature #{@aircon1f_status[:outside_temperature]} deg C
  %input{:type => "submit", :value => "send"}
        
%h2 2f
%form{ :action => "/aircon2f" , :method => "post" }
  %ul
    %li 
      Power 
      #{@aircon2f_status[:power]}
      %select{ :name => 'power' }
        %option{ :value => 'true' ,  :selected => (@aircon2f_status[:power]  ) } ON
        %option{ :value => 'fasle' , :selected => (! @aircon2f_status[:power] ) } off
    %li
      Mode #{@aircon2f_status[:mode]}
    %li
      set temperature  #{@aircon2f_status[:set_temperature]} deg C to 
      %input{ :name=>'set_temperature', :type =>'number' ,:min=>'18' ,:max=>'30',:value=>@aircon2f_status[:set_temperature] } deg C

    %li
      room_humidity  #{@aircon2f_status[:room_humidity]} %
    %li
      room_temperature  #{@aircon2f_status[:room_temperature]} deg C
    %li
      outside_temperature #{@aircon2f_status[:outside_temperature]} deg C

  %input{:type => "submit", :value => "send"}
      


%a{ href: '/' } reload
