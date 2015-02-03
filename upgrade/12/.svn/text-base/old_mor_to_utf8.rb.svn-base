#!/usr/bin/ruby
# -*- encoding : utf-8 -*-
#--------------------description--------------------
# Script for updating all varchars in DB into UTF-8 (ticket #6978)
#
# Params:
# 1 - username
# 2 - password
# 3 - database
# 4 - hostname
#
# Example:
# ruby old_mor_to_utf8.rb mor mor mor localhost
#---------------------------------------------------

mysql = "mysql -u#{ARGV[0].to_s} -p#{ARGV[1].to_s} #{ARGV[2].to_s} -h#{ARGV[3].to_s} -e"
exceptions = "('calls','rights','roles')"

blobs = `#{mysql} "select table_name as '', column_name as '' from information_schema.Columns where data_type = 'blob' and table_schema = '#{ARGV[2].to_s}' and table_name not in #{exceptions}"`.split("\n")
blobs = blobs.map { |row| row.split("\t") }
x = 0
blobs.each do |table,column,i|
    x += 1
    perc = (x*100)/blobs.size
    if table.to_s.strip != "" and column.to_s.strip != ""
       print(`#{mysql} "ALTER TABLE #{table.to_s} MODIFY #{column.to_s} TEXT"`)
       print(`printf '\r[BLOBS => TEXT] #{perc.to_i.to_s}%% Converted'`)
       if x == blobs.size
         print("\n")
       end
    end
end

a = `#{mysql} "select table_name as '', column_name as '' from information_schema.Columns where data_type in ('varchar','text') and table_schema = '#{ARGV[2].to_s}' and table_name not in #{exceptions}"`.split("\n")
b = a.map { |row| row.split("\t") }
total = b.size
i = 0
val = `#{mysql} "select value as '' from conflines where name like 'old_mor_encoding_fix'"`.split("\n")[1].to_s.strip.to_i
if val.to_i == 0 and blobs.size != 0
  b.each do |table, column|
    i = i + 1
    perc = (i*100)/total
    if table.to_s.strip != "" and column.to_s.strip != ""
       print(`#{mysql} "update #{table.to_s} set #{table.to_s}.#{column.to_s} = convert(binary convert(#{table.to_s}.#{column.to_s} using latin1) using utf8)"`)
       print(`printf '\r[varchar/text => utf8] #{perc.to_i.to_s}%% Converted'`)
       if i == total
         print("\n")
         `#{mysql} "insert ignore into conflines (name,value) values ('old_mor_encoding_fix', 1)"`
       end
    end
  end
end


