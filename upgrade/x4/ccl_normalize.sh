#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    This script upgrades devices from older MOR releases in order to match MOR X4 coded logic

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

report "Now will check if CCL was enabled on previous  MOR releases. Will upgrade devices if needed." 3

mysql_connect_data_v2

rvm alias create default ruby-1.9.3-p327@x4 &> /dev/null

ruby /usr/src/mor/upgrade/x4/ccl_normalize.rb "$DB_USERNAME" "$DB_PASSWORD" "$DB_NAME" "$DB_HOST" &> /dev/null
if [ "$?" == "0" ]; then
    report "CCL devices" 0
else
    report "CCL devices upgrade failed. Please contact Kolmisoft to resolve this." 1
fi




