#! /bin/sh

# Author:   Nerijus Šapola
# Company:  Kolmisoft
# Year:     2011
# About:    Script fixes permissions for faxes

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0
fi

check_and_fix_permission /var/spool/asterisk/faxes/ 0777 report

