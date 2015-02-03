#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script checks if stress time was completed on server

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

if [ ! -f "/usr/local/mor/stress_time" ] && [ -f "/usr/local/mor/install_date" ]; then
    report "Stress tests were not completed on this server" 1
fi
 