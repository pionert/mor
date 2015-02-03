#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script checks if stress time was completed on server

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

if [ ! -f "/usr/local/mor/stress_time" ] && [ -f "/usr/local/mor/install_date" ]; then
    report "Stress tests were not completed on this server" 1
else
    report "Stress tests were completed on this server" 0
fi
 