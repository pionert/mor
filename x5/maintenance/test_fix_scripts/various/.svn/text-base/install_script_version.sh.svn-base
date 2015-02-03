#! /bin/sh
. /usr/src/mor/x5/framework/bash_functions.sh

#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  This script checks if the system has the newest revision of install script

install_script_vesion_check()
{
#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  This function checks if the system has the newest revision of install script

#   Arguments:
#       1   -   #{1 - on,0 - off} messages
#
#   Returns:
#       0   -   Install script is already the newest version
#       1   -   Install script needs to be upgraded

    MESSAGES="$1"

    DEBUG=0     # {1 - on, 0 - off}

    INSTALL_SCRIPT_SYSTEM_VERSION=`svn info /usr/src/mor | grep 'Last Changed Rev:' | awk '{print $4}'`
    INSTALL_SCRIPT_REPO_VERSION=`svn info http://svn.kolmisoft.com/mor/install_script/trunk | grep 'Last Changed Rev:' | awk '{print $4}'`

    if [ "$INSTALL_SCRIPT_SYSTEM_VERSION" != "$INSTALL_SCRIPT_REPO_VERSION" ]; then
        if [ "$MESSAGES" == "1" ]; then
            report "There is a newer version of install script, please upgrade install script before doing anything else. Your system revision: $INSTALL_SCRIPT_SYSTEM_VERSION, Repository revision: $INSTALL_SCRIPT_REPO_VERSION " 1
        fi
        if [ "$DEBUG" == "1" ]; then
            echo -e "System install script version: $INSTALL_SCRIPT_SYSTEM_VERSION\nLatest install script version: $INSTALL_SCRIPT_REPO_VERSION";
        fi
        return 1;
    else
        if [ "$MESSAGES" == "1" ]; then
            report "System already has the newest version of MOR install scripts. Revision: $INSTALL_SCRIPT_SYSTEM_VERSION" 0
        fi
        if [ "$DEBUG" == "1" ]; then
            echo -e "System INSTALL script version: $INSTALL_SCRIPT_SYSTEM_VERSION\nLatest install script version: $INSTALL_SCRIPT_REPO_VERSION";
        fi
        return 0;
    fi

}
install_script_vesion_check 1
STATUS="$?"
exit "$STATUS"
