#! /bin/sh
#
#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  This script checks if there are more than one admin users in MOR database

. /usr/src/mor/test/framework/bash_functions.sh

. /usr/src/mor/sh_scripts/mor_install_functions.sh

#------------Functions------------------------
check_if_there_are_more_than_one_admin_user()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This functions checks if there are more than 1 admin users
    #   Returns:
    #       Global variable: MORE_THAN_1_ADMIN_USER="TRUE"  when more than 1 admin user is found

    #   Requirements:       mysql_connect_data_v2      > /dev/null  must be launched before calling this function
    TMP_FILE=`/bin/mktemp`
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT COUNT(*) FROM users WHERE usertype = 'admin'" | (read; cat) > $TMP_FILE
    if [ "$DEBUG" == "1" ]; then cat $TMP_FILE; fi
    USERS=`cat $TMP_FILE`;
    rm -rf $TMP_FILE
    if [ "$USERS" != "" ]; then
        if [ $USERS -gt 1 ]; then
            report "There are more than 1 admin users in MOR database. FIX that!" 1
            MORE_THAN_1_ADMIN_USER="TRUE"
            exit 1
        fi
    else
        report "Unexpected error, when checking if there are more than 1 admin users in a database, check if /home/mor/config/database.yml exists" 1
        exit 1
    fi
}
#--------------------------------------------
check_if_admin_has_id_zero()
{
    #   Author: Mindaugas   Mardosas
    #   Year:   2011
    #   About:  This function checks if admin has id 0 in users table
    #   Returns
    #       1   -  FAILED
    #       0   -   OK
    #       3   -   There are more than 1 user
    TMP_FILE=`/bin/mktemp`
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT id FROM users WHERE usertype = 'admin' and id=0;" | (read; cat) > $TMP_FILE
    ADMIN_USER_ZERO=`cat $TMP_FILE`;
    if [ "$ADMIN_USER_ZERO" != "0" ]; then
        if [ "$MORE_THAN_1_ADMIN_USER" == "TRUE" ]; then
           # report "There are more than 1 admin user, refusing to repair user id" 1
           # exit 1
           return 3
        fi
        return 1 #  admin's ID is not eqaul to 0

    else
        return 0;
    fi    
}

fix_admin_user_id_to_be_zero()
{
    #   Author: Mindaugas   Mardosas
    #   Year:   2011
    #   About:  This function runs SQL to make sure admin user has id 0

    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "UPDATE users SET id=0 WHERE usertype = 'admin';"
}

#--------MAIN -------------
apache_is_running
STATUS="$?";
if [ "$STATUS" != "0" ]; then
    exit 0;
fi

gui_exists
if [ "$?" != "0" ]; then
    exit 0;
fi

DEBUG=0 # 0 - off, 1 - on

mysql_exists
if [ "$?" == "0" ]; then
    mysql_connect_data_v2      > /dev/null
    check_if_there_are_more_than_one_admin_user
    check_if_admin_has_id_zero
    STATUS="$?"
    if [ "$STATUS" == "1" ]; then
        fix_admin_user_id_to_be_zero
        check_if_admin_has_id_zero
        STATUS="$?"
        if [ "$STATUS" == "1" ]; then
            report "Failed to fix admin user id" 1
        elif [ "$STATUS" == "0" ]; then
            report "Fixed admin user id" 4
        else
            report "There are more than 1 admin user. Fix this and run again" 1
        fi
    elif [ "$STATUS" == "3" ]; then
        report "There are more than 1 admin user. Fix this and run again" 1
    fi      
fi
