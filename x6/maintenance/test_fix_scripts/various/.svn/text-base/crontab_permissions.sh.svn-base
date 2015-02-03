#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks permissions related to MOR crontabs

. /usr/src/mor/x6/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
#common

# for crontabs 

check_and_fix_permission /etc/cron.d/mor_monthly_actions 0644 report
check_and_fix_permission /etc/cron.d/mor_logrotate 0644 report
check_and_fix_permission /etc/cron.d/mor_auto_dialer 0644 report
check_and_fix_permission /etc/cron.d/mor_hourly_actions 0644 report
check_and_fix_permission /etc/cron.d/mor_daily_actions 0644 report
