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
  # creating model associations
  class Lcr	< ActiveRecord::Base
    belongs_to :user
  end

  class User	< ActiveRecord::Base
    belongs_to :lcr
  end
rescue Exception => e
  EXIT[1, e]
end

# iterating users
begin
  id_pool = Array.new

  ALL_RSPRO = User.where(own_providers: 1, usertype: 'reseller')
  ALL_RSPRO.each do |rs|
    blank_lcr = Lcr.where(name: 'BLANK', user_id: rs.id).first || Lcr.create(name: 'BLANK', user_id: rs.id)
    rs_users = User.where(owner_id: rs.id)
    rs_users.each do |user|
      if user.lcr and user.lcr.user_id != rs.id
        user.lcr_id = blank_lcr.id
        user.save
        id_pool << user.id
      end
    end
  end
  STDOUT.puts "-- BLANK Lcr assigned to these users: (#{id_pool.join(',')})" unless id_pool.size.zero? # AS: MM request for support.
  EXIT[0, nil, 'DONE']
rescue Exception => e
  EXIT[1, e]
end
