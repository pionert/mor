#! /bin/sh

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2013
# About:    Script checks and fix incorrect ulimit value in safe_asterisk

. /usr/src/mor/x5/framework/bash_functions.sh

MAXFILES=$(( `cat /proc/sys/fs/file-max` / 2 ))						#safe_asterisk calculates ulimit value in this way
ulimit -n $MAXFILES &>/dev/null									#check if we can set that value calculated by Asterisk
if [ "$?" == "1" ]; then								#if not then
    grep "ulimit -n \$MAXFILES" /usr/sbin/safe_asterisk &>/dev/null			#check if safe_asterisk is not fixed already
    if [ "$?" == "0" ]; then								#and if it is not then
        sed -i 's|ulimit -n $MAXFILES|ulimit -n 131072|g' /usr/sbin/safe_asterisk	#we are setting harcoded value on safe_asterisk to be used for ulimit
	report "ulimit -n 131072 is added to /usr/sbin/safe_asterisk, because Asterisk was not able to set its ulimit value. Asterisk restart is needed to take effect" 4
	report "Asterisk restart is needed to take effect!" 2
    else
        report "Asterisk cannot set its ulimit value, but safe_asterik is already fixed. Nothing to do." 0
    fi
    exit 0;
fi
report "Asterisk can set its ulimit value. Nothing to do." 0
