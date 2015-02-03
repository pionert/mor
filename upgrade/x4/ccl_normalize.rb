#!/usr/bin/ruby
# -*- encoding : utf-8 -*-

# Script by Aurimas Š.
# Used for fixing SIP server devices with ipauth when ccl is on. (Ticket: #7543)
#
# Params:
# 1 - mysql username
# 2 - mysql password
# 3 - mysql database
# 4 - hostname
#
# Usage:
# ruby ccl_normalize.rb username password database hostname
#
# Notes:
# RUBY VERSION SHOULD Be 1.9.1 or higher.

require 'rubygems'
require 'active_record'

# DB init
begin
  ActiveRecord::Base.establish_connection(
	adapter:  'mysql2',
	database: ARGV[2],
	username: ARGV[0],
	password: ARGV[1],
	host:	  ARGV[3]
  )

  ActiveRecord::Base.connection
rescue
  # bad mysql settings. sending negative status signal
  Signal.trap('EXIT') { exit 1 }
  err = 1
end

begin

  if err.blank?
    class ServerDevice	< ActiveRecord::Base; attr_accessible :server_id; end
    class Device	< ActiveRecord::Base; self.inheritance_column = :ruby_type; end 
    class Server	< ActiveRecord::Base; end
    class Confline	< ActiveRecord::Base; end

  # CLL status check
    ccl_var    = Confline.where(name: 'CCL_Active').first
    ccl_status = ccl_var ? ccl_var.value.to_i : 0

  # cleanup engine
  end

  if ccl_status == 1 and err.nil?
    # Servers
    admin_ast = Confline.where(name: "Default_asterisk_server").first.try(:value) || Server.first.id
    sip_proxy = Server.where(server_type: "sip_proxy").first.try(:id)	  || Server.first.id # in case it's not present

    # SIP ipauth devices
    server_devices = ServerDevice.select('server_devices.*').
		joins("join devices on devices.id = device_id").
		where("device_type = 'SIP' and server_devices.server_id != '#{sip_proxy}' and host not in ('','dynamic')")
  
    unless server_devices.blank?
      id_pool	   = server_devices.collect(&:device_id).uniq.compact
      devices	   = Device.where(id: id_pool)

      # cleaning and updating devices
      server_devices.each do |server_device|
        if id_pool.include? server_device.device_id
          # server device
          server_device.update_attributes(server_id: sip_proxy)
          # device
          device			= devices.select {|device| device.id = server_device.device_id }.first
          device.insecure		= 'port,invite'
          device.server_id		= sip_proxy
          device.save
          # removing device from pool
          id_pool.delete(server_device.device_id)
        else
          # not in pool = duplicate.
          server_device.destroy
        end
      end
    end
  end
  # exit status for bash
  Signal.trap('EXIT') { exit (err.blank? ? 0 : 1) }
rescue
  # exit status for bash
  Signal.trap('EXIT') { exit 1 }
end
