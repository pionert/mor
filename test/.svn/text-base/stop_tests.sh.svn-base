#! /bin/sh
#   Author: Mindaugas Mardosas
#   Year:   2013
#   About:  THis 

. /usr/src/mor/test/framework/bash_functions.sh
ps aux | grep mor | awk '{print $2}' | xargs kill
service httpd stop
killall -9 firefox

report "Testing stopped" 3