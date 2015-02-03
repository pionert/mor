#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This scripts searches for signs that the system was hacked

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
if [ -f "/dev/saux" ]; then
    report "/dev/saux detected. The system is hacked!" 1
fi

if [ -d "/etc/ssh2" ]; then
    report "/etc/ssh2 detected. This directory is not created by MOR install. The system is hacked!" 1
fi

