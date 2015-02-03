#! /bin/sh

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2014
# About:    script checks if /usr/src/mor/sh_scripts/asterisk/db/import_changes.sh was launched on server

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

read_mor_asterisk_settings
if [ "$ASTERISK_PRESENT" != "1" ]; then
    exit 0; #we will not be able to determine what Asterisk version we have on system if Asterisk is on other server.
fi

mysql_connect_data_v2

asterisk_is_running
if [ "$RUNNING" == "0" ]; then
    asterisk_current_version
    if [ "$ASTERISK_BRANCH" == "1.8" ]; then
        /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "desc devices" | grep "auth" | grep -v "authuser" > /dev/null
        if [ "$?" == "0" ]; then
            report "Columns in [devices] table are ok" 0
        else
            report "Columns are missing in devices table. Run /usr/src/mor/sh_scripts/asterisk/db/import_changes.sh to fix it" 1
        fi
    fi
fi