# Script by -Aurimas. S.- //2013//

require 'active_record'
require 'ipaddr'
require 'yaml'

# Configuration
ENV_DB	= '/home/mor/config/database.yml'
DEBUG	= ARGV.member?('-v')
FORCE	= ARGV.member?('-f')
COLUMNS = %w{ peerip recvip sipfrom uri useragent peername t38passthrough }

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
rescue Exception => e
  EXIT[1, e]
end

begin
  # adding columns to call_details table
  class Migrate < ActiveRecord::Migration; end
    Migrate.verbose = DEBUG
    Migrate.class_eval do
      change_table :call_details do |t|
        t.column :peerip,    'INT(10) unsigned '
        t.column :recvip,    'INT(10) unsigned '
        t.column :sipfrom,   'varchar(255)'
        t.column :uri,	     'varchar(255)'
        t.column :useragent, 'varchar(255)'
        t.column :peername,  'varchar(255)'
        t.column :t38passthrough, 'tinyint(4)'
      end
    end
rescue Exception => e
  e.message.include?("Duplicate column name") ? (EXIT[0] unless FORCE) : EXIT[1, e] 
end

# DB integrity check
begin
  # Creating models
  class Call		< ActiveRecord::Base
    has_one :call_detail
  end
  class CallDetail	< ActiveRecord::Base
    belongs_to :call
  end
  # provoking exception
  Call.first.blank?
  CallDetail.first.blank?
rescue Exception => e
  EXIT[1, e]
end

# moving data
begin
  SIZE = Call.where("sipfrom != ''").count

  index = 0

  Call.where("sipfrom != ''").find_in_batches do |calls|
    calls.each do |call|
      details = call.call_detail
      if details.blank?
        details = CallDetail.new
        details.call_id = call.id
      end
      COLUMNS.each do |column|
        value = call[column.to_sym]
        details[column.to_sym] = ['peerip','recvip'].member?(column) ? (IPAddr.new(value).to_i rescue nil) : value
      end
      details.save
      perc = ((100.0/SIZE)*index).to_i
      print "\r[#{['+','x'][index%2]}] #{perc}% call_details\r"
      index = index.next
    end
  end
rescue Exception => e
  e.message.include?('Unknown column') ? (EXIT[0, nil, "nothing changed"] unless FORCE) : EXIT[1, e]
end

# dropping columns from calls
#begin
#  Migrate.class_eval do
#    change_table(:calls) do |t|
#      COLUMNS.each {|col| t.remove col.to_sym }
#    end
#  end
EXIT[0, nil, "done, #{SIZE} call_details updated/created"]
#rescue Exception => e
#  e.message.include?('column/key exists') ? EXIT[0, nil, "nothing changed"] : EXIT[1, e]
#end
