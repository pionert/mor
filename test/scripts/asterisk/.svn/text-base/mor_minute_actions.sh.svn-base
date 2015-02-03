#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script deletes mor_minute_actions if Asterisk is not running on server

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------


#--------MAIN -------------

get_ccl_status

asterisk_is_running
if [ "$?" != "0" ] || [ "$CCL_STATUS" == "1" ]; then
    if [ -f "/etc/cron.d/mor_minute_actions" ]; then
        report "Detected that Asterisk is not running or it is behind SIP Proxy, deleting /etc/cron.d/mor_minute_actions crontab as it is not needed" 4
        rm -rf /etc/cron.d/mor_minute_actions
    fi
else
    if [ ! -f "/etc/cron.d/mor_minute_actions" ]; then
        mor_core_version
        if [ "$MOR_CORE_BRANCH" -ge "11" ]; then
                report "Detected that Asterisk is running and /etc/cron.d/mor_minute_actions does not exist, creating one." 4
                echo -e "# update peer information from Asterisk to DB\n*/10 * * * * root /usr/local/mor/mor_retrieve_peers" > /etc/cron.d/mor_minute_actions
        fi
    fi
fi