#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script adds logrotate for mor gui debug files: /tmp/mor_debug.log and /tmp/mor_debug.txt

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi


echo "/tmp/mor_debug.txt /tmp/mor_debug.log {
    daily
    notifempty
    compress
    rotate 5
    copytruncate
    }" > /etc/logrotate.d/mor_gui_debug

# TODO this is not a test!
report "Logrotates to /mor_gui_debug are ok" 0