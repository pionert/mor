#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script detects if a virtual machine is in use.

. /usr/src/mor/x5/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

detect_vm
if [ "$?" == "0" ]; then
    report "This host is running as: $VM_TYPE virtual machine" 3
else
    report "This is real server (not VM)" 0
fi
