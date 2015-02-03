#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script installs a tool required for netwrok packets capturing.
#           http://www.wireshark.org/

. /usr/src/mor/x6/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
#--------MAIN -------------
if [ ! -f /usr/sbin/tethereal ]; then
    report "Wireshark not present will install" 2
    yum -y install wireshark
    # TODO check if really
    report "Wireshark installed" 3
else
    report "Wireshark present" 0
fi



