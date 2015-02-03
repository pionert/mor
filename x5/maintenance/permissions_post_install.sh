#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks permissions related to MOR GUI and fixes if any problems are found

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

check_and_fix_permission /home/mor/tmp 0777 report ignore
touch /home/mor/log/development.log
check_and_fix_permission /home/mor/log/development.log 0777 report
touch /home/mor/log/production.log
check_and_fix_permission /home/mor/log/production.log 0777 report
check_and_fix_permission /var/log/httpd/access_log 0777 report
check_and_fix_permission /var/log/httpd/error_log 0777 report
check_and_fix_permission /root/phpMyAdminPassword  0700 report
chown apache:apache -R /home/mor
check_and_fix_permission /home/mor  0700 report
# autodialer
mkdir -p /home/mor/public/ad_sounds
mkdir -p /var/lib/asterisk/sounds/mor
if [ ! -f "/var/lib/asterisk/sounds/mor/ad" ]; then
    ln -s /home/mor/public/ad_sounds /var/lib/asterisk/sounds/mor/ad &> /dev/null
fi
check_and_fix_permission /var/lib/asterisk/sounds/mor/ad 0777 report
check_and_fix_permission /home/mor/public/ad_sounds  0777 report
