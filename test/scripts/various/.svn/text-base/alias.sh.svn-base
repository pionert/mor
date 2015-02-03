#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
alias_is_enabled()
{
    # Author: Mindaugas Mardosas
    # Company: Kolmisoft
    # Year: 2011
    # About: This function checks if default MOR aliases are enabled

    grep mor_aliases /root/.bashrc &> /dev/null
    if [ "$?" != "0" ]; then
        return 1;
    else
        return 0;
    fi
}
enable_aliases()
{
    # Author: Mindaugas Mardosas
    # Company: Kolmisoft
    # Year: 2011
    # About: This function enables default MOR aliases

    alias_is_enabled
    STATUS="$?"
    if [ "$STATUS" == "0" ]; then
        return 0;
    elif [ "$STATUS" == "1" ]; then
        
        echo 'if [ -f /usr/src/mor/test/files/mor_aliases.sh ]; then source /usr/src/mor/test/files/mor_aliases.sh; fi' >> /root/.bashrc

        alias_is_enabled    
        STATUS="$?"
        if [ "$STATUS" == "0" ]; then
            return 4;
        else
            return 1;
        fi
    fi
}

#--------MAIN -------------

enable_aliases
STATUS="$?"
if [ "$STATUS" == "0" ]; then
    report "MOR aliases enabled" 0;
elif [ "$STATUS" == "4" ]; then
    report "MOR aliases enabled" 4;
elif [ "$STATUS" == "1" ]; then
    report "MOR aliases enabled" 1;
fi

