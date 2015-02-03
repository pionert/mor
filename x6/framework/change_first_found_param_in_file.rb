#!/usr/bin/env ruby

# Script that changes first occurance of given string to second string in a file.
# Usage:
# ruby change_param.rb file/name.txt what_to_search_for what_to_insert
#
# Author: Martynas Margis
# GPL :)

file_name, target, string, file_lines= ARGV[0],ARGV[1],ARGV[2], []

File.open(file_name, "r"){ |file|
  while (line = file.gets)
    file_lines << line
  end
}

file_lines.each_with_index{|line, i|
if line.match(/^#{target}/)
  file_lines[i] = string.to_s + "\n"
  break
end
}

File.open(file_name, "w"){|f| f.write(file_lines.join(""))}

