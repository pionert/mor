#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script deletes duplicate indexes on cards table

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
# Drop duplicate "number" indexes from cards

apache_is_running
STATUS="$?";
if [ "$STATUS" != "0" ]; then
    exit 0;
fi

gui_exists
if [ "$?" != "0" ]; then
    exit 0;
fi

mor_gui_current_version
if [ "$MOR_VERSION" == "10" ] || [ "$MOR_VERSION" == "11" ] || [ "$MOR_VERSION" == "12" ] || [ "$MOR_VERSION" == "12.126" ]; then
    mysql_connect_data_v2
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "show indexes from cards;" | grep number* | grep -v number_unique | awk '{print $3}' | while read name; do /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "drop index $name on cards;"; done
fi