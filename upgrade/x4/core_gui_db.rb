# Script by -Aurimas. S.- //2013//

require 'active_record'
require 'yaml'

# Configuration
ENV_DB	= '/home/mor/config/database.yml'
DEBUG	= ARGV.member?('-v')
#FORCE	= ARGV.member?('-f')
#COLUMNS = %w{ core gui db }

# Exit handler
EXIT = Proc.new do |code, e, msg|
  if DEBUG and (e or msg)
    output = [msg, (e.message if e.respond_to? :message)].join
    STDERR.puts "-- " << output 
  end
  ActiveRecord::Base.remove_connection if ActiveRecord::Base.connected?
  Kernel::exit! code
end

# network layer
begin
  # Reading database config
  DB = YAML::load(File.open(ENV_DB))
  # Connecting to production database
  ActiveRecord::Base.establish_connection(DB['production'])
  # creating Server model
  class Server < ActiveRecord::Base; end
rescue Exception => e
  EXIT[1, e]
end

begin
  CORE_FIELD	= Server.where(core: 1).count.to_i.zero?
  GUI_FIELD	= Server.where(gui:  1).count.to_i.zero?
  DB_FIELD	= Server.where(db:   1).count.to_i.zero?

  EXIT[0, nil, 'NOTHING TO DO'] if !CORE_FIELD and !DB_FIELD and !GUI_FIELD

  default_server = Server.order('server_id ASC').first
  default_server.core =	1 if CORE_FIELD
  default_server.db   =	1 if DB_FIELD
  default_server.gui  = 1 if GUI_FIELD

  EXIT[0, nil, 'DONE'] if default_server.save
rescue Exception => e
  EXIT[1, e]
end
