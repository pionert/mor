#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks if context  please_login exists in devices table

. /usr/src/mor/x5/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

please_login_context()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks if there are please_login contexts in a database

    # Returns:
    #       0   -   OK, please_login contexts not detected in devices table
    #       1   -   FAILED, please_login contexts found in devices table

    mysql_connect_data_v2      > /dev/null
    NUMBER_OF_CONTEXTS=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT count(id) FROM devices WHERE context='please_login';" | (read; cat)`
    if [ "$NUMBER_OF_CONTEXTS" != "0" ] ; then
        return 1;
    else
        return 0;
    fi
}

#--------MAIN -------------

asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0;
fi


please_login_context
STATUS="$?"

if [ "$STATUS" == "0" ]; then
    report "please_login context in devices table: SELECT id FROM devices WHERE context='please_login';" 0
else
    report "Found please_login contexts in devices table: SELECT id FROM devices WHERE context='please_login';\nRun fix.sh to fix this" 1
fi
