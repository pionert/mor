#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks if core and gui versions match

. /usr/src/mor/x5/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
core_version_mapper()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2013
    # About:    This function maps MOR core versions to MOR GUI versions mapper
    #
    # Arguments:
    #   $1  -   MOR_CORE_BRANCH
    
    local VERSION="$1"
    
    if [ "$VERSION" == "0.8" ]; then
        MOR_MAPPED_CORE_VERSION_WEIGHT="80"
        return 80
    fi
    if [ "$VERSION" == "9" ]; then
        MOR_MAPPED_CORE_VERSION_WEIGHT="90"
        return 90
    fi
    if [ "$VERSION" == "10" ]; then
        MOR_MAPPED_CORE_VERSION_WEIGHT="100"
        return 100
    fi
    if [ "$VERSION" == "11" ]; then
        MOR_MAPPED_CORE_VERSION_WEIGHT="110"
        return 110
    fi
    if [ "$VERSION" == "12" ]; then   # Ask older Kolmisoft staff about this mess :)
        MOR_MAPPED_CORE_VERSION_WEIGHT="123"
        return 123
    fi    
    if [ "$VERSION" == "14" ]; then
        MOR_MAPPED_CORE_VERSION_WEIGHT="140"
        return 140
    fi
    if [ "$VERSION" == "15" ]; then
        MOR_MAPPED_CORE_VERSION_WEIGHT="150"
        return 150
    fi

}

check_if_core_and_gui_versions_match()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This script checks if core and gui versions match
    #
    # This function depends on functions mor_core_version and mor_gui_current_version

    mor_core_version
    mor_gui_current_version
    
    core_version_mapper "$MOR_CORE_BRANCH"
    mor_version_mapper "$MOR_VERSION_YOU_ARE_TESTING"
    
    if [ "$MOR_MAPPED_CORE_VERSION_WEIGHT" == "$MOR_MAPPED_VERSION_WEIGHT" ]; then
        return 0
    else
        return 1
    fi
}

#--------MAIN -------------
asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0
fi
apache_is_running
STATUS="$?";
if [ "$STATUS" != "0" ]; then
    exit 0;
fi
gui_exists
if [ "$?" == "1" ]; then
    exit 0;
fi
#----------------

check_if_core_and_gui_versions_match
if [ "$?" != "0" ]; then
    report "CORE AND GUI VERSIONS DO NOT MATCH! MOR Core version: $MOR_CORE_VERSION <-> MOR GUI version: $MOR_VERSION_YOU_ARE_TESTING" 2
else
    report "CORE AND GUI VERSIONS MATCH! Core version: $MOR_CORE_VERSION <-> GUI version: $MOR_VERSION_YOU_ARE_TESTING" 0
fi
