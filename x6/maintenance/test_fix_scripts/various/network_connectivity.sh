#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks if a server can ping google.com 3 times successfully

. /usr/src/mor/x6/framework/bash_functions.sh

#------VARIABLES-------------
export LANG="en_US.UTF-8"

#----- FUNCTIONS ------------



check_ping()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks if the server can ping google.com 3 times successfully

    # Returns:
    #   0   -   OK
    #   1   -   Failed

    local ADDRESS_TO_PING="$1"
    ping -c 3 $ADDRESS_TO_PING | grep "3 received" &> /dev/null

    if [ "$?" == "0" ]; then
        return 0
    else
        return 1
    fi
}

#---------------------------

report "Checking network connectivity" 3

check_ping "google.com"
if [ "$?" == "0" ]; then
    report "Network connectivity OK: ping -c 3  google.com" 0
else
    check_ping "yahoo.com"
    if [ "$?" == "0" ]; then
        report "Network connectivity: ping -c 3  yahoo.com" 0
    else    
        check_ping "kolmisoft.com"
        if [ "$?" == "0" ]; then
            report "Network connectivity OK: ping -c 3  kolmisoft.com" 0
        else
            report "Network connectivity: ping -c 3  google.com and ping -c 3  yahoo.com and ping -c 3 kolmisoft.com" 1
        fi
    fi   
fi
