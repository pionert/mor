#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script adds logrotates for various asterisk related logs

. /usr/src/mor/x6/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0;
fi

add_logrotate_if_not_present "/var/log/mor/ami_debug.log" "mor_ami_debug"

add_logrotate_if_not_present "/var/log/mor/record_file.log" "record_file"

