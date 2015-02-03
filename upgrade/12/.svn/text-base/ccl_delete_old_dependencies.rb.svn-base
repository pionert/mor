# Script by -Aurimas. S.- //2013//

require 'active_record'
require 'yaml'

# Configuration
ENV_DB	= '/home/mor/config/database.yml'
DEBUG	= ARGV.member?('-v')
#FORCE	= ARGV.member?('-f')

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
  class Serverprovider < ActiveRecord::Base; end
  class ServerDevice < ActiveRecord::Base; end
  class Server < ActiveRecord::Base; end
rescue Exception => e
  EXIT[1, e]
end

begin
  SERVERS       = Server.select([:id, :server_id])

  # find and destroy all serverproviders with not found provider
  serv_prov     = (
    Serverprovider.select("serverproviders.id").
      joins("LEFT JOIN providers p ON (p.id = serverproviders.provider_id)").
      where("p.id IS NULL OR serverproviders.server_id NOT IN (#{SERVERS.map(&:server_id).join(",")})")
  )

  # find and destroy all server_devices with not found device
  serv_dev      = (
    ServerDevice.select("server_devices.id").
      joins("LEFT JOIN devices d ON (server_devices.device_id = d.id)").
      where("d.id IS NULL OR server_devices.server_id NOT IN (#{SERVERS.map(&:id).join(",")})")
  )

  EXIT[0, nil, 'NOTHING TO DO'] if serv_prov.blank? and serv_dev.blank?

  serv_prov.destroy_all unless serv_prov.blank?
  serv_dev.destroy_all unless serv_dev.blank?

  EXIT[0, nil, 'DONE'] if serv_prov.blank? and serv_dev.blank?
rescue Exception => e
  EXIT[1, e]
end
