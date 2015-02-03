#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks if WEB_URL is set correctly (other value than default 127.0.0.1) in /home/mor/config/environment.rb

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

apache_is_running
if [ "$?" != "0" ]; then
    exit 0
fi

DEFAULT_IP=`grep Web_URL /home/mor/config/environment.rb | awk -F"/|\"" '{print $4}'`
if [ "$DEFAULT_IP" == "127.0.0.1" ]; then
    report "Please set WEB_URL variable to match your server IP in /home/mor/config/environment.rb" 1
else
    RESOLVED_IP=`resolveip $DEFAULT_IP 2> /dev/null | grep "IP address" | awk '{print $NF}'` &>/dev/null
    if [ "$RESOLVED_IP" != "" ] && [ "$RESOLVED_IP" != "127.0.0.1" ]; then
        DEFAULT_IP="$RESOLVED_IP"
    fi
    ifconfig | grep $DEFAULT_IP &> /dev/null    # checking if the ip/hostname set in environment.rb matches the one displayed by ifconfig
    if [ "$?" == "0" ]; then
        report "WEB_URL variable in /home/mor/config/environment.rb" 0
    else
        report "WEB_URL variable in /home/mor/config/environment.rb does not match any resolved IP displayed by ifconfig. Please make sure here is no mistake." 3
    fi
fi
