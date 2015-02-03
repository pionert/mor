#! /bin/sh
 
# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script disables yum-updatesd daemon because of the bugs in it
#
# Other notes:
#   fix.sh scripts depend on this script and its location, do not move it anywhere and do not rename

. /usr/src/mor/x6/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

check_if_yum_updatesd_is_enabled()
{
#   Author:   Mindaugas Mardosas
#   Company:  Kolmisoft
#   Year:     2011
#   About:    This function checks if yum-updatesd  is enabled
#
#   Returns:
#       0   -   OK. yum-updatesd is disabled
#       1   -   Failed. yum-updatesd is enabled and must be disabled

    chkconfig --list | grep yum-updatesd | grep on &> /dev/null
    if [ "$?" == "0" ]; then
        return 1;
    else
        return 0;
    fi
}

#--------MAIN -------------
check_if_yum_updatesd_is_enabled
STATUS="$?"
if [ "$STATUS" == "1" ]; then
    /sbin/chkconfig --levels 2345 yum-updatesd off
    /sbin/service yum-updatesd stop

    #checking again
    check_if_yum_updatesd_is_enabled
    STATUS2="$?"
    if [ "$STATUS2" == "0" ]; then
        report "yum-updatesd was successfully disabled" 4
    else
        report "Failed to disable yum-updatesd" 1
    fi
else
    report "yum-updatesd disabled" 0
fi
