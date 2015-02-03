#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2010
# About:    This script checks if binaddr is set in /etc/asterisk/sip.conf if heartbeat is detected in the system

. /usr/src/mor/x6/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
etc_asterisk_sip_conf_binaddr()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2010
    # About:    This funkc checks if binaddr is set in /etc/asterisk/sip.conf and default 0.0.0.0 is not left there

    binadd_ip=`grep binaddr /etc/asterisk/sip.conf | awk '{print $2}'`
}
#--------MAIN -------------
#----- heartbeat checks---
heartbeat_is_running
STATUS="$?"
if [ "$STATUS" == "2" ]; then
    report "HeartBeat is installed, but not running" 3
    exit 1;
fi

if [ "$STATUS" == "1" ]; then       # HeartBeat is not installed nothing to do in this script
    report "HeartBeat is not installed" 3
    exit 0;
fi

if [ "$STATUS" == "3" ]; then       # HeartBeat is not installed nothing to do in this script
    report "An error occoured when checking HeartBeat status: /etc/init.d/heartbeat does not exist" 1
    exit 1
fi

#----- /checks---
asterisk_is_running #if asterisk is present and running in the system
STATUS="$?"
    #   0 - OK, Asterisk is running in the system
    #   1 - FAILED, Asterisk is not running in the system
    #   2 - Asterisk is not present in the system
if [ "$STATUS" == "0" ]; then
    check_if_setting_match /etc/asterisk/sip.conf "bindaddr" "bindaddr=0.0.0.0"
    if [ "$?" == "0" ]; then
        report "HeartBeat is running, and bindaddr=0.0.0.0 is found in /etc/asterisk/sip.conf, please set this variable to correct virtual ip" 1
        exit 1
    else
        BIND_ADDR_IP=`grep bindaddr /etc/asterisk/sip.conf | awk '{print $1}'` &> /dev/null
        if [ "$BIND_ADDR_IP" == "" ]; then
            report "HeartBeat is running, and bindaddr variable with virtual IP is not set in /etc/asterisk/sip.conf" 1
            exit 1
        else
            report "HeartBeat is running, and $BIND_ADDR_IP found in /etc/asterisk/sip.conf" 0
            exit 0
        fi
    fi

fi


