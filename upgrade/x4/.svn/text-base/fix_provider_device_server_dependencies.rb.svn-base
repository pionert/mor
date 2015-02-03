# Script by -Dmitrij. A.- //2013//

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
  class Device < ActiveRecord::Base; end
  class Confline < ActiveRecord::Base; end
  class Server < ActiveRecord::Base; end
rescue Exception => e
  EXIT[1, e]
end

begin
  SERVERS	= Server.select([:id, :server_id, :server_type])

  # find and destroy all serverproviders with not found provider
  serv_prov     = (
    Serverprovider.select("serverproviders.id").
      joins("LEFT JOIN providers p ON (p.id = serverproviders.provider_id)").
      where("p.id IS NULL OR serverproviders.server_id NOT IN (#{SERVERS.map(&:server_id).join(",")})")
  )
  serv_prov.destroy_all unless serv_prov.blank?

  # find and destroy all server_devices with not found device
  serv_dev      = (
    ServerDevice.select("server_devices.id").
      joins("LEFT JOIN devices d ON (server_devices.device_id = d.id)").
      where("d.id IS NULL OR server_devices.server_id NOT IN (#{SERVERS.map(&:id).join(",")})")
  )
  serv_dev.destroy_all unless serv_dev.blank?

  # create server_devices for assigned providers
  serv_prov_dev = Device.select("devices.id AS device_id, providers.id AS provider_id, device_type").joins("JOIN providers ON providers.device_id = devices.id").where("devices.user_id != -1")

  ccl_active = Confline.where(name: "CCL_Active").first.try(:value)
  sip_proxy_server = Server.where(server_type: "sip_proxy").first
  serv_prov_dev.each do |d|
    Serverprovider.where(provider_id: d.provider_id).each do |s|
      if ccl_active.to_i == 1 and d.device_type == "SIP"
        ServerDevice.create(device_id: d.device_id, server_id: sip_proxy_server.id) if sip_proxy_server.present? and ServerDevice.where(device_id: d.device_id, server_id: sip_proxy_server.id).first.nil?
      else
	id = SERVERS.select {|i| i.server_id == s.server_id}.first.try(:id)
        ServerDevice.create(device_id: d.device_id, server_id: id) if ServerDevice.where(device_id: d.device_id, server_id: id).first.nil?
      end
    end
  end

  # create server_devices if ccl is off
  if ccl_active.to_i == 0
    cond = "AND devices.id NOT IN (#{serv_prov_dev.collect(&:device_id).join(",")})" if serv_prov_dev.size > 0
    devs = Device.select("devices.id, devices.server_id").joins("LEFT JOIN server_devices ON devices.id = server_devices.device_id").where("devices.user_id != -1 #{cond.to_s} AND server_devices.id IS NULL AND name NOT LIKE 'mor_server_%'")
    devs.each do |d|
      if d.server_id.to_i > 0
        ServerDevice.create(device_id: d.id, server_id: d.server_id)
      else
        s = SERVERS.select {|i| i.server_type == "asterisk" and active == 1}.first.try(:id)
        s = SERVERS.select {|i| i.server_type == "asterisk" and active == 0}.first.try(:id) if s.nil?
        ServerDevice.create(device_id: d.id, server_id: s)
      end
    end
  end

  EXIT[0, nil, 'DONE'] if serv_prov.blank? and serv_dev.blank?
rescue Exception => e
  EXIT[1, e]
end
