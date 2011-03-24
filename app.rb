require 'sinatra'
require 'sinatra/sequel'
require 'haml'
require 'json'
require 'rack-flash'

enable :sessions
use Rack::Flash, :sweep => true

set :database, ENV['DATABASE_URL'] || 'sqlite://my.db'

class Address < Sequel::Model
  plugin :schema
  set_schema do
    varchar :ip, :unique => true; index :ip;
  end
  create_table unless table_exists?
end

class Vote < Sequel::Model
  plugin :schema
  set_schema do
    primary_key :id
    integer :jesus
    integer :barabbas
  end
  create_table unless table_exists?
  if empty?
    create :jesus => 0, :barabbas => 0
  end
  
  def inc field
    database.run("UPDATE votes SET #{field} = #{field} + 1 WHERE (id = 1);")
  end
end

get '/' do
  @barabbas = Vote[1].barabbas || 0
  @jesus = Vote[1].jesus || 0
  @barabbas_p = "%.1f" % (@barabbas / (@jesus + @barabbas).to_f * 100.0) || "0.0%"
  @jesus_p = "%.1f" % (@jesus / (@jesus + @barabbas).to_f * 100.0) || "0.0%"
  @barabbas_p = "0.0" if @barabbas_p == "NaN"
  @jesus_p = "0.0" if @jesus_p == "NaN"
  haml :home
end

post '/' do
  env['HTTP_X_REAL_IP'] ||= env['REMOTE_ADDR']
  begin
    Address.create :ip => env['HTTP_X_REAL_IP']
    
    if params["b"]
      Vote[1].inc("barabbas")
    elsif params["j"]
      Vote[1].inc("jesus")
    else
      raise new Exception
    end
    
    flash[:notice] = "Thanks for your vote!"
  rescue Sequel::DatabaseError
    flash[:notice] = "You can vote only once!"
  rescue Exception
    flash[:notice] = "Caught you, idiot!"
  end
  
  redirect '/'
end