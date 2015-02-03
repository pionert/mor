#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks permissions related to MOR GUI and fixes if any problems are found

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

apache_is_running
if [ "$?" != "0" ]; then
    exit 1;
fi

check_and_fix_permission /home/mor/log/fastcgi.crash.log 0777 report ignore
check_and_fix_permission /home/mor/log/development.log 0777 report
check_and_fix_permission /home/mor/log/production.log 0777 report
check_and_fix_permission /var/log/httpd/access_log 0777 report
check_and_fix_permission /var/log/httpd/error_log 0777 report
check_and_fix_permission /root/phpMyAdminPassword  0700 report


apache_is_running
gui_exists
if [ "$APACHE_IS_RUNNING" == "0" ] && [ "$MOR_GUI_EXIST" == "0" ]; then
	touch /tmp/mor_debug.txt &> /dev/null
	check_and_fix_permission /tmp/mor_debug.txt 0777 report
fi

