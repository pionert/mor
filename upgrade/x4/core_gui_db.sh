#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    needed only for X3->X4 migration.
# More information here. http://trac.kolmisoft.com/trac/ticket/7803

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

apache_is_running
if [ "$?" != "0" ]; then
    exit 1;
fi

/usr/local/mor/mor_ruby /usr/src/mor/upgrade/x4/core_gui_db.rb
if [ "$?" != "0" ]; then
    report "Failed to migrate DB. More information on this here: http://trac.kolmisoft.com/trac/ticket/7803" 1
fi