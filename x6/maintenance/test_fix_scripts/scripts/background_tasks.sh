#! /bin/sh

# Author:   Nerijus Sapola  
# Company:  Kolmisoft
# Year:     2014
# About:    Script checks if background tasks are configured properly.

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

# check if cronjob is present
if [ ! -f "/etc/cron.d/mor_background_tasks" ]; then
    report "Background tasks are not present here" 3
    exit 0;
fi

# run the script so it generates log file which we will check
# this hides the problem that cronjob does not work properly
# but solves the problem when on fresh install 1min is not passed and this script is reported as not running
# TODO think of better way to test this script on fresh install
/usr/local/mor/mor_background_tasks

tail -n 5 /var/log/mor/mor_background_tasks.log | grep "Waiting_tasks" &> /dev/null
if [ "$?" == "0" ]; then
    report "mor_background_tasks script works fine" 0
    exit 0;
else
    report "mor_background_tasks script does not work. Check /var/log/mor/mor_background_tasks.log" 1
    exit 1;
fi
