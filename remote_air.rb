require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'
require 'sinatra/reloader'
require './AirConditioner.rb'
require './AirCleaner.rb'

set :port, 4568
set :bind, '0.0.0.0'


STDOUT.sync = true
STDERR.sync = true

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end


get '/' do
  tmp = AirConditioner.new  "192.168.33.111", [ 0x01, 0x30, 0x04]
  @aircon1f_status = tmp.get_status

  tmp = AirConditioner.new  "192.168.33.111", [0x01, 0x30, 0x03]
  @aircon2f_status = tmp.get_status

  tmp = AirCleaner.new  "192.168.33.126", [ 0x01, 0x35, 0x01]
  @airclean2f_status =tmp.get_status

  haml :index
end

post  '/aircon1f'  do
  tmp = AirConditioner.new  "192.168.33.111",[ 0x01, 0x30, 0x04]
  power= ( params[:power]=="true"?true:false)
  tmp.set_power power
  val=params[:set_temperature].to_i
  tmp.set_temp  val
  tmp.send
  haml :ok
end

post  '/aircon2f'  do
  tmp = AirConditioner.new  "192.168.33.111",[0x01, 0x30, 0x03]
  power= ( params[:power]=="true"?true:false)
  tmp.set_power power
  val=params[:set_temperature].to_i
  tmp.set_temp  val
  tmp.send
  haml :ok
end

post  '/aircleaner2f'  do
  tmp = AirCleaner.new  "192.168.33.126", [0x01, 0x35, 0x01]
  power= ( params[:power]=="true"?true:false)
  tmp.set_power power
  tmp.send
  haml :ok
end

__END__

@@ style
h1
  margin-top: 1em
  font-size: 16pt
  text-align: left

h2
  margin-top: 1em
  font-size: 12pt
  text-align: left

li
  font:
    size: 1em

contents
  margin: 2px 2px 2px 2px

#foot
  margin: 20px 20px 20px 20px


  
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
%h1 remote air web --#{Time.now}--
%h2 send command ok
%a{ href: '/' } jump to status 

@@ index
%h1 remote air web --#{Time.now}--
%h2 1f aircon
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
        
%h2 2f aircon
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

%h2 2f aircleaner
%form{ :action => "/aircleaner2f" , :method => "post" }
  %ul
    %li 
      Power 
      #{@airclean2f_status[:power]}
      %select{ :name => 'power' }
        %option{ :value => 'true' ,  :selected => (@airclean2f_status[:power]  ) } ON
        %option{ :value => 'fasle' , :selected => (! @airclean2f_status[:power] ) } off
    %li
      AirFlowRateSetting #{@airclean2f_status[:flowRate]}
    %li
      AirPollutionDetectionStatus #{@airclean2f_status[:pollution]}

  %input{:type => "submit", :value => "send"}

  

%div#foot
  %a{ href: '/' } reload
