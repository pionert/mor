#! /bin/sh

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2014
# About:    This script adds logrotate for mor debug files: /var/log/mor/blacklist.log

. /usr/src/mor/x5/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

add_logrotate_if_not_present "/var/log/mor/blacklist.log" "mor_blacklist"