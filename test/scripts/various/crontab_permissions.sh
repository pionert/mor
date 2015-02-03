#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks permissions related to MOR crontabs

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
#common

# for crontabs 

check_and_fix_permission /etc/cron.d/mor_monthly_actions 0644 report
check_and_fix_permission /etc/cron.d/mor_logrotate 0644 report
check_and_fix_permission /etc/cron.d/mor_ad 0644 report
check_and_fix_permission /etc/cron.d/mor_hourly_actions 0644 report
check_and_fix_permission /etc/cron.d/mor_daily_actions 0644 report
check_and_fix_permission /etc/cron.d/ntpdate 0644 report


