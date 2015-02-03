#! /bin/sh
# Year:     2013
# About:    This script recompiles all assets

. /usr/src/mor/test/framework/bash_functions.sh


rm -rf /home/mor/app/assets/javascripts/dtree.js
rm -rf /home/mor/tmp
mkdir -p /home/mor/app/assets
cd /home/mor


rvm alias create default ruby-1.9.3-p327@x4
rvm use ruby-1.9.3-p327@x4

bundle


report "Cleaning Assets" 3
rake assets:clean &> /dev/null #--trace
report "Recompiling assets" 3
rake assets:precompile &> /dev/null #--trace
mkdir -p /home/mor/tmp /home/mor/app/assets
chmod 777 -R /home/mor/tmp /home/mor/app/assets

# this file should be empty and readable		
rm -fr /home/mor/Gemfile.lock 
touch /home/mor/Gemfile.lock 
chmod 666 /home/mor/Gemfile.lock

service httpd restart

