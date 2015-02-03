#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    This script migrates sipchaninfo data

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

# checking if MOR X4 is installed
mor_gui_current_version
mor_version_mapper "$MOR_VERSION" 
if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "140" ]; then
    ruby  /usr/src/mor/upgrade/x4/sipchaning.rb  -v
fi