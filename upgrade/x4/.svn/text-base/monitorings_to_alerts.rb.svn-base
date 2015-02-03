# Script by -Dmitrij A.- //2013//
# [39720] - stable version with working monitorings

require 'active_record'
require 'yaml'

# Configuration
ENV_DB  = '/home/mor/config/database.yml'
DEBUG   = ARGV.member?('-v')
# FORCE  = ARGV.member?('-f')

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
  class Monitoring < ActiveRecord::Base; end
  class MonitoringsUser < ActiveRecord::Base; end
  class Alert < ActiveRecord::Base; end
rescue Exception => e
  EXIT[1, e]
end

begin
  monitorings = Monitoring.all rescue []
  monitorings_users = MonitoringsUser.all rescue []

  if monitorings.blank?
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS monitorings;")
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS monitorings_users;")
    ActiveRecord::Base.connection.execute("ALTER TABLE users DROP COLUMN ignore_global_monitorings;") rescue 0 
    ActiveRecord::Base.connection.execute("DELETE FROM acc_group_rights WHERE acc_right_id IN (SELECT id FROM acc_rights WHERE name IN ('monitorings_manage','monitorings'));")
    ActiveRecord::Base.connection.execute("DELETE FROM acc_rights WHERE name IN ('monitorings_manage','monitorings');")

    EXIT[0, nil, 'NOTHING TO DO']
  end

  monitorings.each do |mon|
    details = {}
    details[:status] = mon.active ? 'enabled' : 'disabled'
    details[:count_period] = mon.period_in_past > 1440 ? 1440 : mon.period_in_past
    amount = mon.amount.to_d / (mon.period_in_past > 1440 ? mon.period_in_past / 60 : 1)
    if mon.monitoring_type == 'above'
      details[:alert_if_more] = amount
      details[:alert_if_less] = 0
    elsif mon.monitoring_type == 'bellow'
      details[:alert_if_less] = amount
      details[:alert_if_more] = 0
    elsif mon.monitoring_type == 'simultaneous'
      details[:alert_if_more] = 2
      details[:alert_if_less] = 0
    end
    details[:disable_clear] = 1
    details[:alert_type] = mon.mtype.to_i == 1 ? 'price_sum' : 'sim_calls'
    details[:check_type] = 'user'
    if mon.user_type.blank?
      begin
	details[:check_data] = monitorings_users.select {|m| m.monitoring_id == mon.id}.first.user_id
      rescue
	details[:check_data] = nil
	details[:status] = 'disabled'
      end
    else
      details[:check_data] = mon.user_type
    end
    details[:action_alert_disable_object] = mon.block
    details[:comment] = 'Alert transferred from Monitorings'
    details[:owner_id] = mon.owner_id


    alert = Alert.new(details)
    alert.save

  end

  `mysqldump mor monitorings monitorings_users > /usr/local/mor/backups/monitorings_backup.sql`
  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS monitorings;")
  ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS monitorings_users;")
  ActiveRecord::Base.connection.execute("ALTER TABLE users DROP COLUMN ignore_global_monitorings;") rescue 0
  ActiveRecord::Base.connection.execute("DELETE FROM acc_group_rights WHERE acc_right_id IN (SELECT id FROM acc_rights WHERE name IN ('monitorings_manage','monitorings'));")
  ActiveRecord::Base.connection.execute("DELETE FROM acc_rights WHERE name IN ('monitorings_manage','monitorings');")

  EXIT[0, nil, 'DONE']
rescue Exception => e
  EXIT[1, e]
end

