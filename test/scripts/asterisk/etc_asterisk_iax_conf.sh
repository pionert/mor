#! /bin/sh
# Author:   Mindaugas Mardosas
# Year:     2010
# About:    This script checks if /etc/asterisk/iax.conf config has default variable: requirecalltoken=no, if YES - reports OK, if NO - reports Failed

# Arguments:
    # no arguments are accepted

. /usr/src/mor/test/framework/bash_functions.sh

#----------------------------

requirecalltoken()
{
    # Author:   Mindaugas Mardosas
    # Year:     2010
    # About:    This function checks if /etc/asterisk/iax.conf config has default variable: requirecalltoken=no, if YES - reports OK, if NO - reports Failed

    # Arguments:
        # no arguments are accepted

    #   Returns
    #       0   -   setting requirecalltoken=no in /etc/asterisk/iax.conf is OK
    #       1   -   Failed to fix the setting
    #       4   -   Setting was successfully fixed
    
    # If requirecalltoken=no was added at the end of file by previuos script version,
    # remove it
    if tail -n 1 /etc/asterisk/iax.conf | grep -q "requirecalltoken=no"; then
        sed -i '$ d' /etc/asterisk/iax.conf
    fi

    check_if_setting_match /etc/asterisk/iax.conf "requirecalltoken" "requirecalltoken=no"
    STATUS="$?";
    if [ "$STATUS" == "0" ]; then
        report "/etc/asterisk/iax.conf requirecalltoken=no" 0
        return 0
    elif [ "$STATUS" == "2" ]; then #setting was not found at all, adding in [general] section
         sed -i '/\[general\]/a requirecalltoken=no' /etc/asterisk/iax.conf 
        
    elif [ "$STATUS" == "1" ]; then #setting did not matched
        replace_line /etc/asterisk/iax.conf "requirecalltoken" "requirecalltoken=no"
    fi

    check_if_setting_match /etc/asterisk/iax.conf "requirecalltoken" "requirecalltoken=no"
    STATUS="$?"
    if [ "$STATUS" == "0" ]; then
        report "/etc/asterisk/iax.conf requirecalltoken=no" 4
        report "Asterisk restart is needed" 3
        return 4
    else
        report "/etc/asterisk/iax.conf requirecalltoken=no" 1
        return 1
    fi
}

#================= MAIN ====================
asterisk_is_running

if [ "$?" != "0" ]; then
    exit 0
fi
separator "Checking /etc/asterisk/iax.conf"

requirecalltoken
exit "$?"
