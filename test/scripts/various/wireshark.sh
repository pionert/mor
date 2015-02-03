#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script installs a tool required for netwrok packets capturing.
#           http://www.wireshark.org/

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
#--------MAIN -------------
if [ ! -f /usr/sbin/tethereal ]; then
    yum -y install wireshark
fi



