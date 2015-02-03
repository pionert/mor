#! /bin/sh
#   Author: Mindaugas Mardosas
#   Year:   2011
#   About:  This script checks if Apache webserver exists and is runing
. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

apache_is_running
STATUS="$?"
if [ "$STATUS" == "1" ]; then
    report "Apache is installed but is not running" 1
else
    report "Apache is running" 0
fi

