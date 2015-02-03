#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    This script fixes LCR problems when marking Reseller user as Reseller PRO. More information about this here: http://trac.kolmisoft.com/trac/ticket/7825

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

apache_is_running
if [ "$?" != "0" ]; then
    exit 0
fi

ruby /usr/src/mor/upgrade/12/rspro_lcr_unassign.rb
if [ "$?" != "0" ]; then
    report "Failed to check/fix problems related to RS and RSPRO LCR. More information about this here: http://trac.kolmisoft.com/trac/ticket/7825" 1
fi