#! /bin/sh

# Author:   Mindaugas Mardosas, Nerijus Sapola
# Company:  Kolmisoft
# Year:     2014
# About:    This script checks if sip registrations variable in /etc/asterisk/sip.conf is correctly configured

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0
fi

_mor_time   #initialize

if [ `awk -F";" '{print $1}' /etc/asterisk/sip.conf | grep registerattempts | wc -l` == "0" ] || [ `awk -F";" '{print $1}' /etc/asterisk/sip.conf | grep registertimeout | wc -l` == "0" ]; then
    report "Backing up /etc/asterisk/sip.conf to /usr/local/mor/backups/asterisk/etc/sip.conf_$mor_time" 3
    mkdir -p /usr/local/mor/backups/asterisk/etc/
    cp /etc/asterisk/sip.conf /usr/local/mor/backups/asterisk/etc/sip.conf_$mor_time
fi

if [ `awk -F";" '{print $1}' /etc/asterisk/sip.conf | grep registerattempts | wc -l` == "0" ]; then # If option is commented out
    sed -i 's/;registerattempts=10/registerattempts=0/' /etc/asterisk/sip.conf
    if [ `awk -F";" '{print $1}' /etc/asterisk/sip.conf | grep registerattempts | wc -l` == "1" ]; then # If option is commented out
        report "Configured /etc/asterisk/sip.conf: registerattempts=0"  4
    else
        report "Failed to configure /etc/asterisk/sip.conf: registerattempts=0"  1
    fi
else
    report "registerattempts in sip.conf is ok" 0
fi

if [ `awk -F";" '{print $1}' /etc/asterisk/sip.conf | grep registertimeout | wc -l` == "0" ]; then # If option is commented out
    sed -i 's/;registertimeout=20/registertimeout=180/' /etc/asterisk/sip.conf
    if [ `awk -F";" '{print $1}' /etc/asterisk/sip.conf | grep registertimeout | wc -l` == "1" ]; then # If option is commented out
        report "Configured /etc/asterisk/sip.conf: registertimeout=180"  4
    else
        report "Failed to configure /etc/asterisk/sip.conf: registertimeout=180"  1
    fi
else
    report "registertimeout in sip.conf is ok" 0
fi