#! /bin/sh

# Author:   Nerijus Sapola  
# Company:  Kolmisoft
# Year:     2014
# About:    Script checks if background tasks are configured properly.

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

if [ ! -f "/etc/cron.d/mor_background_tasks" ]; then
    report "Background tasks are not present here" 0
    exit 0;
fi

tail -n 5 /var/log/mor/m2_background_tasks.log | grep "Starting MOR Background Tasks script" &> /dev/null
if [ "$?" == "0" ]; then
    report "Background tasks work fine" 0
    exit 0;
else
    report "Background tasks does not work. Check /var/log/mor/m2_background_tasks.log" 1
    exit 1;
fi