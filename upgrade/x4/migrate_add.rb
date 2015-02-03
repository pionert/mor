# Script by -Aurimas. S.- //2013//

require 'active_record'
require 'yaml'

# Configuration
ADDONS	= %w{ AD_sounds_path AD_Active CC_Active RS_Active RSPRO_Active SMS_Active REC_Active PG_Active MA_Active CS_Active CC_Single_Login PROVB_Active AST_18 WP_Active CALLB_Active  }
ENV_RB	= '/home/mor/config/environment.rb'
DEBUG	= ARGV.member?('--debug') ? true : false
FORCE	= ARGV.member?('--force') ? true : false


# Exit handler
EXIT = Proc.new do |code, e, msg|
    if DEBUG and (e or msg)
	output = [msg, (e.try(:message) if e.is_a? Class)].join
	STDERR.puts output 
    end
    ActiveRecord::Base.remove_connection if ActiveRecord::Base.connected?
    Kernel::exit! code.to_i
end

# network layer
begin
    # Reading database config
    DB = YAML::load(File.open('/home/mor/config/database.yml'))

    # Connecting to production database
    ActiveRecord::Base.establish_connection(DB['production'])

    # Creating Confline model
    class Confline < ActiveRecord::Base; end

rescue Exception => e
    EXIT[1, e, "Check database.yml: "]
end

# Parsing environment.rb
begin
    ENV_RB_MATCHES = File.read(ENV_RB).split("\n").grep(/#{ADDONS.join("|")}/)
    ENV_RB_MATCHES.collect! do |match|
	match.gsub(/(\s+|\")/, '').split("=")
    end
    EXIT[0, nil, "environment.rb is clean"] if ENV_RB_MATCHES.size.zero?
rescue Exception => e
    EXIT[1, e, "Can't parse Environment.rb: "]
end

# Checking conflines for addons present
begin
    DB_ADDONS = Confline.select([:name, :value]).where(name: Hash[ENV_RB_MATCHES].keys)
    DB_ADDONS.map! { |db_addon| [db_addon.name, db_addon.value] }    
rescue Exception => e
    EXIT[1, e]
end

# should we continue?
EXIT[0, nil, "Addons are already moved"] if not FORCE and DB_ADDONS.size == ENV_RB_MATCHES.size

# Moving config to Conflines
begin
    QUEUE = ENV_RB_MATCHES.reject { |key, val| Hash[DB_ADDONS].keys.member? key }
    QUERY = QUEUE.collect do |name, value|
	{name: name, value: value}
    end
    Confline.create(QUERY)

    if FORCE
	DB_ADDONS.each do |addon, value|
	    Confline.where(name: addon).first.update_attributes(value: Hash[ENV_RB_MATCHES][addon])
	end
    end
    hit = QUERY.size
    hit += DB_ADDONS.size if FORCE
    EXIT[0, nil,"#{hit} addons moved to Conflines"]
rescue Exception => e
    EXIT[1, e]
end
