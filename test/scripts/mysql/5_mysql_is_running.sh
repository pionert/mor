#! /bin/sh
#   Author: Mindaugas Mardosas
#   Year:   2011
#   About:  This script checks if MySQL is installed and is runing
. /usr/src/mor/test/framework/bash_functions.sh

mysql_is_running
STATUS="$?"
if [ "$STATUS" == "1" ]; then
    report "MySQL is installed but is not running" 3
fi
