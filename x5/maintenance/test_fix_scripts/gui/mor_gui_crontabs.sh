#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks MOR crontabs and fixes if possible.

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

#--------MAIN -------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

apache_is_running
STATUS="$?";
if [ "$STATUS" != "0" ]; then
    exit 0;
fi

gui_exists
if [ "$?" != "0" ]; then
    exit 0;
fi

# todo: shows FAILED somehow but all works, problem with reporting

fix_mor_gui_crontab "/callc/hourly_actions" "/etc/cron.d/mor_hourly_actions" "0 * * * * root wget --no-check-certificate -o /dev/null -O /dev/null "
    report "Crontab: /etc/cron.d/mor_hourly_actions" "$?"

fix_mor_gui_crontab "/callc/daily_actions" "/etc/cron.d/mor_daily_actions" "0 0 * * * root wget --no-check-certificate -o /dev/null -O /dev/null "
    report "Crontab: /etc/cron.d/mor_daily_actions" "$?"

fix_mor_gui_crontab "/callc/monthly_actions" "/etc/cron.d/mor_monthly_actions" "10 0 1 * * root wget --no-check-certificate -o /dev/null -O /dev/null "
    report "Crontab: /etc/cron.d/mor_monthly_actions" "$?"

