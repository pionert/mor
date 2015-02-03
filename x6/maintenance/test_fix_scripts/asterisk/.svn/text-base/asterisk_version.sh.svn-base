#! /bin/sh

#   Author: Mindaugas   Mardosas
#   Year:   2010
#   About:  This script checks current Asterisk version and warns if asterisk version is lower than given

#   Exit status:
#   0 - OK, Asterisk is the newest version, or does not exist in this system - nothing to do
#   1 - Failed, Asterisk is outdated

. /usr/src/mor/x6/framework/bash_functions.sh


#------VARIABLES-------------

#--------MAIN -------------

asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0;
fi

asterisk_current_version
mor_core_version
if [ "$?" != "1" ]; then    #if core is present in the system
    if [ "$MOR_CORE_BRANCH" -le "11" ]; then
        NEWEST_ASTERISK_VERSION="1.4.42"
    else
        NEWEST_ASTERISK_VERSION="1.8.32.1"
    fi

    if [ "$ASTERISK_VERSION" == "$NEWEST_ASTERISK_VERSION" ]; then
        report "Asterisk version: $ASTERISK_VERSION" 0
        exit 0
    else
        report "Your Asterisk version: $ASTERISK_VERSION, newest Asterisk version: $NEWEST_ASTERISK_VERSION. If possible - please upgrade to the newest Asterisk version" 2
        exit 1
    fi
fi
