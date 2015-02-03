#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script fixes UTF problems for MOR 12. Important - this fix script uses Ruby script for DB fix, so it is important that this script would be run on GUI server.

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

# checking if MOR 12 is installed
mor_gui_current_version
mor_version_mapper "$MOR_VERSION" 
if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "123" ] && [ ! -f "/usr/local/mor/utf_fix_lock_extend_to_x3" ]; then
    mysql_connect_data_v2
    touch /usr/local/mor/utf_fix_lock_extend_to_x3  # prevention for futre script run
    ruby /usr/src/mor/upgrade/12/old_mor_to_utf8.rb $DB_USERNAME $DB_PASSWORD $DB_NAME $DB_HOST 2> /dev/null
fi