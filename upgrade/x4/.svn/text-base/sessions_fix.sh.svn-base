#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    Author: This script fixes MOR sessions

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
check_if_rc_conf_has_script_launch_script_inserted()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This functions checks and inserts sessions folder fix script in /etc/rc.local if needed
    
    if [ `grep sessions_fix.sh /etc/rc.local | wc -l` == "0" ]; then
        echo "/usr/local/mor/sessions_fix.sh"  >> /etc/rc.local
    fi
    
}
#--------MAIN -------------
if [ -f "/usr/src/mor/upgrade/x4/sessions_fix.sh" ]; then
    cp -fr /usr/src/mor/upgrade/x4/sessions_fix.sh /usr/local/mor/  # Updating script
fi

check_if_rc_conf_has_script_launch_script_inserted

mkdir -p /dev/shm/sessions
chmod 777 -R /dev/shm/sessions
rm -rf /dev/shm/sessions/*