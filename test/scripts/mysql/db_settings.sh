#! /bin/sh

#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  This script checks if every config which defines settings to connect to MySQL is set up correctly
#
. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------


apache_is_running
    HTTPD_STATUS="$?"   

asterisk_is_running
    ASTERISK_STATUS="$?"

if [ "$HTTPD_STATUS" == "0" ] ||  [ "$ASTERISK_STATUS" == "0" ]; then
    mysql_connect_data_v2 test
fi
