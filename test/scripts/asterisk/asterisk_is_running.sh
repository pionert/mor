#! /bin/sh
#   Author: Mindaugas Mardosas
#   Year:   2011
#   About:  This script checks if Asterisk exists and is runing
. /usr/src/mor/test/framework/bash_functions.sh

asterisk_is_running
STATUS="$?"
if [ "$STATUS" == "1" ]; then
    report "Asterisk is installed but is not running" 3
fi
