#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This scripts searches for signs that the system was hacked

. /usr/src/mor/x5/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
if [ -f "/dev/saux" ]; then
    report "/dev/saux detected. The system is hacked!" 1
else
    report "Hack check: /dev/saux not detected" 0
fi

if [ -d "/etc/ssh2" ]; then
    report "/etc/ssh2 detected. This directory is not created by MOR install. The system is hacked!" 1
else
    report "Hack check: /etc/ssh2 not detected" 0
fi

