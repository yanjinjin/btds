require 'netaddr'
require 'snorby/model/counter'

class Log

  include DataMapper::Resource

  property :id, Serial

  property :optime, String
  property :ip, String
  property :username, String
  property :opobject, String
  property :opdetail, String
  
  def self.empty
    sql="delete from logs;"
    db_execute(sql)
  end

end
