#!/usr/bin/ruby
# encoding: utf-8

#Vitalija Vildžiūtė
#2012-10-11
#Version : 3

require 'rubygems'
require 'active_record'
require 'optparse'
require 'digest/sha1'

options = {}
optparse = OptionParser.new do|opts|

  # Define the options, and what they do
  options[:name] = nil
  opts.on( '-n', '--name NAME', "Database name, default ''" ) do|n|
    options[:name] = n
  end

  options[:user] = nil
  opts.on( '-u', '--user USER', "Database user, default ''" ) do|u|
    options[:user] = u
  end

  options[:pasw] = nil
  opts.on( '-p', '--password PASSWORD', "Database password, default ''" ) do|p|
    options[:pasw] = p
  end

  options[:host] = nil
  opts.on( '-s', '--server HOST', "Database host, default 'localhost'" ) do|h|
    options[:host] = h
  end

  options[:table] = nil
  opts.on( '-t', '--table TABLE', "Table name" ) do|t|
    options[:table] = t
  end

  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    puts
    exit
  end
end

optparse.parse!


#---------- SET CORECT PARAMS TO SCRIPT ! ---------------

Debug_file = '/tmp/utf_test.log'
Database_name = options[:name].to_s.empty?  ? ''  : options[:name]
Database_username = options[:user].to_s.empty?  ? ''  : options[:user]
Database_password = options[:pasw].to_s.empty?  ? ''  : options[:pasw]
Database_host =  options[:host].to_s.empty? ? 'localhost'  : options[:host]
Table_name =  options[:table].to_s.empty? ? ''  : options[:table]
Output_file = "/tmp/utf_#{Time.now.to_i}.sql"

begin
  #---------- connect to DB ----------------------
  ActiveRecord::Base.establish_connection(:adapter => "mysql", :database => Database_name, :username => Database_username, :password => Database_password, :host => Database_host)
  ActiveRecord::Base.connection

  #------------- Debug model ----------------
  class Debug
    def Debug.debug(msg)
      File.open(Debug_file, "a") { |f|
        f << msg.to_s
        f << "\n"
      }
    end
  end

  #------------- MyWritter model ----------------
  class MyWritter
    def MyWritter.msg(msg)
      File.open(Output_file, "a") { |f|
        f << msg.to_s + "\n"
      }
    end

  end
  
  #------------- MyHelper model ----------------
  class MyHelper
    def MyHelper.output(value)
      case value.class.to_s
      when 'Integer'
        out = value.to_i
      when 'String'
        out = "'#{MyHelper.my_escape_char(value)}'"
      when 'Time'
        out = "'#{value.to_s(:db)}'"
      when 'Date'
        out = "'#{value.to_s(:db)}'"
      when 'Float'
        out = value.to_f
      else
        out = "'#{MyHelper.my_escape_char(value)}'"
      end
      return out
    end

    def MyHelper.my_escape_char(string)
      st1 = string.gsub(/\\'/, '@mano_norimas_stringas_123@@')
      st2 = st1.gsub(/\\\\/, '@mano_norimas_stringas_12345@@')
      st3 = st2.split('\\')
      st4 = st3.join("\\\\")
      st5 = st4.split(/'/)
      st6 = st5.join("\\'")
      st7 = st6.split('@mano_norimas_stringas_123@@')
      st8 = st7.join("\\'")
      st9 = st8.split('@mano_norimas_stringas_12345@@')
      return  st9.join("\\\\")
    end
  end

  #------------------ Main -------------------
  Debug.debug("\n*******************************************************************************************************")
  Debug.debug("#{Time.now().to_s(:db)} --- STARTING ")

  if Table_name.blank?
    change_tables = ActiveRecord::Base.connection.tables
  else
    change_tables = [Table_name]
  end

  MyWritter.msg "# -------------- Bloob change into Text -----------------\n"
  MyWritter.msg 'alter table acc_groups change description description text;
alter table cron_settings change description description text;
alter table hangupcausecodes change description description text;
alter table payments change description description text;
alter table ringgroups change comment comment text;
alter table invoices change comment comment text;
alter table cs_invoices change comment comment text;
alter table callerids change comment comment text;
alter table call_logs change log log text;
alter table conflines change value2 value2 text;
alter table cron_actions change last_error last_error text;
alter table emails change body body text; '
    

  change_tables.each{|t|
    if !['calls', 'call_log', 'ratedetails', 'rates', 'aratedetails', 'rights', 'role_rights', 'roles', 'flatrate_data'].include?(t.to_s)
    file = "# -------------- #{t} -----------------\n"
    Debug.debug("#{Time.now().to_s(:db)} #{file} ")
    rows = ActiveRecord::Base.connection.select_all("SELECT * FROM #{t};")
    strings = []
    rows.each_with_index{|r, i|
      op = 0
      string = []
      r.sort.each{|key, value|
        if t.to_s != 'destinations' and !['prefix', 'direction_code'].include?(key.to_s)
          if value.class.to_s == 'String' and !value.blank?
          op = 1
          string << " `#{key}` = #{MyHelper.output(value)} "
          end
        end
      }
      if op == 1
        if t.to_s == 'voicemail_boxes'
          strings <<  "UPDATE #{t} SET #{string.join(" , ")} WHERE uniqueid= #{r['uniqueid']};" if string.size.to_i > 0
        else
          strings <<  "UPDATE #{t} SET #{string.join(" , ")} WHERE id = #{r['id']};" if string.size.to_i > 0
        end
      end
    }
    if strings.size.to_i > 0
      MyWritter.msg file
      MyWritter.msg strings.join("\n")
    end
end
  }
  puts "DONE : #{Output_file} "
end

ActiveRecord::Base.remove_connection
