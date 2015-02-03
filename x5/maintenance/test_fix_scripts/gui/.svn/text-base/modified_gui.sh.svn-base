#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks if user has modified his gui

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
gui_is_modified()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2010
    # About:    This function checks if MOR gui is modified

    #   Returns:
    #       0 - OK, gui is not modified by user
    #       1 - Failed, gui IS MODIFIED BY USER

    if [ ! -f /usr/bin/svn ]; then
        yum -y install subversion
    fi

    
    svn status /home/mor | grep -v -F "Gemfile.lock" | awk '{print $1}' | grep "^M" &> /dev/null
    
    if [ "$?" == "0" ]; then
        report "User has modified his GUI" 3
    else
	report "GUI is not modified" 0
    fi
}
#--------MAIN -------------
apache_is_running
STATUS="$?";
if [ "$STATUS" != "0" ]; then
    exit 0;
fi

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

gui_is_modified
