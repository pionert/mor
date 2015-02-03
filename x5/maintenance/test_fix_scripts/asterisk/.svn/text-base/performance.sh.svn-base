#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This test is for servers performance. It checks if there is enabled logging

. /usr/src/mor/x5/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0;
fi

#----- LOGGER ------

if [ `awk -F";" '{print $1}' /etc/asterisk/logger.conf | grep "debug\|full" | wc -l` != "0" ]; then
    report "You have left debug or full logging options in /etc/asterisk/logger.conf, comment them out for maximum server performance:" 3
else
    report "/etc/asterisk/logger.conf debug and full logging options disabled, all good" 0
fi


if [ `awk -F";" '{print $1}' /etc/asterisk/logger.conf | grep "messages" | wc -l` != "1" ]; then
    report "You have not enabled messages logging option in /etc/asterisk/logger.conf because of this Fail2Ban will not be able to work properly" 1
else
    report "/etc/asterisk/logger.conf messages logging ok, Fail2Ban can work" 0
fi



#---- CSV ------

NUMBER_OF_LOGGING_OPTIONS_LEFT=`grep -A 3 -B 0 "\[csv\]" /etc/asterisk/cdr.conf | awk -F";" '{print $1}' | grep "usegmtime\|loguniqueid\|loguserfield" | wc -l`

if [ "$NUMBER_OF_LOGGING_OPTIONS_LEFT" != "0" ]; then
    report "You have left logging options in /etc/asterisk/cdr.conf, comment them out for maximum server performance:" 3
    grep -A 3 -B 0 "\[csv\]" /etc/asterisk/cdr.conf | awk -F";" '{print $1}' | grep "usegmtime\|loguniqueid\|loguserfield"
else
    report "/etc/asterisk/cdr.conf logging options ok" 0
fi