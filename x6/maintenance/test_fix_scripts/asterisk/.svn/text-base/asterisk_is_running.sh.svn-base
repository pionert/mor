#! /bin/sh
#   Author: Mindaugas Mardosas
#   Year:   2011
#   About:  This script checks if Asterisk exists and is runing
source /usr/src/mor/x6/framework/bash_functions.sh

asterisk_is_running
STATUS="$?"
if [ "$STATUS" == "1" ]; then
    report "Asterisk is installed but is not running" 2
else
    report "Asterisk is running" 0
fi
