#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks if extensions_mor_pbxfunctions.conf contains line: #include extensions_mor_external_did.conf

. /usr/src/mor/x6/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0;
fi

#separator "Other tests related to asterisk"

mor_core_version "EXIT_IF_NO_CORE"
if [ "$MOR_CORE_BRANCH" -ge "10" ]; then    #IF MOR version is 10 or higher
    if [ -f /etc/asterisk/extensions_mor_pbxfunctions.conf ]; then
        asterisk_include_directive "/etc/asterisk/extensions_mor_pbxfunctions.conf" "extensions_mor_external_did.conf"
            report "/etc/asterisk/extensions_mor_pbxfunctions.conf: #include extensions_mor_external_did.conf" "$?"
    else
        report "/etc/asterisk/extensions_mor_pbxfunctions.conf does not exist. It indicates, that you have to run fix.sh, and run the tests again" 6
        exit 1;
    fi
fi
