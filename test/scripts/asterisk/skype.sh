#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks and updates if needed Asterisk configurations to be compatible with skype

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
#--------MAIN -------------
asterisk_is_running 'exit'  #exits if asterisk is not running in this machine
mor_core_version "EXIT_IF_NO_CORE"

if [ "$MOR_CORE_BRANCH" -gt "9" ]; then #if MOR 10=<
    separator "Asterisk: Skype"

    if [ ! -f "/etc/asterisk/chan_skype.conf" ]; then
        report "/etc/asterisk/chan_skype.conf is not present - run fix.sh to fix this"  6
    else
        asterisk_exec_directive /etc/asterisk/chan_skype.conf "/usr/local/mor/mor_ast_skype" "FIX"
        report "#exec /usr/local/mor/mor_ast_skype in /etc/asterisk/chan_skype.conf" "$?"
    fi

    if [ ! -f /usr/local/mor/mor_ast_skype ]; then
        report "/usr/local/mor/mor_ast_skype is not present - run fix.sh to fix this" 6
    else
        report "/usr/local/mor/mor_ast_skype is present" 0
    fi
fi
