require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'
require 'sinatra/reloader'

set :port, 4568
set :bind, '0.0.0.0'


STDOUT.sync = true
STDERR.sync = true

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end

get '/' do
  haml :index
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
    %meta{:"http-equiv"=>"Content-Type", :content=>"text/html", |
          :charset=>"utf-8"}
    %link{:rel=>"stylesheet", :type=>"text/css", :href=>"/style.css"}
  %body
    #contents
      != yield

@@ index
%h1 hello



