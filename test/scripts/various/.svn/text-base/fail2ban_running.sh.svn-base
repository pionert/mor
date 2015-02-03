#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script checks if fail2ban is runing in this system

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
fail2ban_started
if [ "$?" == "0" ]; then
    report "Fail2Ban is running" 0
    exit 0
else
    report "Fail2Ban is not running!" 1
    exit 1
fi

