#! /bin/sh

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2013
# About:    script checks if option "MySQL is located on remote server" is enabled on GUI servers where database is located on remote server.

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

read_mor_gui_settings

if [ "$GUI_PRESENT" == "1" ]; then
    read_mor_db_settings
    if [ "$DB_PRESENT" == "0" ]; then
        mysql_connect_data_v2 > /dev/null
        current_value=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "select value from conflines where name='Load_CSV_From_Remote_Mysql'\G" | grep value | awk '{print $2}'`
        if [ "$current_value" == "1" ]; then
            report "Database is on remote server and option is on. Nothing to do" 0;
            exit 0;
        elif [ "$current_value" == "0" ]; then
            report "Database is on remote server, but option 'MySQL is located on remote server' is not enabled. Please fix it" 1
            exit 0;
        else
            report "Failed to retrieve valid value while checking 'MySQL is located on remote server' option" 1
            exit 1;
        fi
    else
        report "Database is on localhost, nothing to do" 0
        exit 0;
    fi
else
    report "GUI is not on localhost, nothing to do" 0
    exit 0;
fi