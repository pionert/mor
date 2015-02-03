# -*- encoding : utf-8 -*-
#!/usr/bin/ruby
# encoding: utf-8

#Vitalija Vildžiūtė
#2012-10-19
#Version : 1
#Kolmisoft

# run 
# ruby path_to_file/strip_replace.rb path_to_dir_to_replace
# example 
# ruby /home/witta/strip_replace.rb /home/witta/darbas/12.126
# output
# /home/witta/darbas/12.126/app/controllers/*
# /home/witta/darbas/12.126/app/controllers/providers_controller.rb#<MatchData "].strip">


path = ARGV[0] # get path
if path and path.to_s != ''
  [path + '/app/controllers/*', path + '/app/models/*', path + '/app/views/*/*', path + '/app/helpers/*'].each { |versija|
    puts versija
    @files = Dir.glob(versija)

    for file in @files

      if !File.directory?(file)
        html = ''
        #read
        File.open(file, 'r+') do |f|
          while (!f.eof?)
            html += f.readline
          end

        end

        # find strings in file
        # check is strip is and strip is not after &: !
        if html.match(/[^(.to_s)?].strip/) and !html.match(/&:strip/) and !html.match(/to_s.strip/)
          z = html.to_s.gsub(/.strip/, '.to_s.strip')
          puts file + html.match(/[^(.to_s)?].strip/).inspect
          # replace file
          File.open(file, 'r+') do |f|
            f.syswrite(z)
          end

        else
          # no matches found
        end
      end
    end    
  }
end
