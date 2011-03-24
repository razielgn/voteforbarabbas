require 'sinatra'
require 'sequel'
require 'haml'

configure do
end

get '/' do
  haml :home
end