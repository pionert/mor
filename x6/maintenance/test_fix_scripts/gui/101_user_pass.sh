#! /bin/sh

# Author:   Mindaugas Mardosas, Nerijus Sapola
# Company:  Kolmisoft
# Year:     2012
# About:    This script creates a hardly guessable password

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#------VARIABLES-------------


#----- FUNCTIONS ------------
current_user_101_password()
{
    # Author:   Mindaugas Mardosas, Nerijus Sapola
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function checks current MOR test user password.
    #   Returns:
    #       0  password is not equal "101"
    #       1  password is default "101"
    #   Other notes:
    #       This function depends on function mysql_connect_data_v2

    CURRENT_USER_101_PASSWORD=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT password FROM users WHERE id = 2"  | (read; cat)` &> /dev/null

    if [ "$CURRENT_USER_101_PASSWORD" == "dbc0f004854457f59fb16ab863a3a1722cef553f" ]; then
        return 1
    else
        return 0
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

mysql_connect_data_v2
current_user_101_password
if [ "$?" != "0" ]; then
    generate_random_password 12
    MOR_sha1_hash=`echo -n $GENERATED_PASSWD | sha1sum | awk '{ print $1}' | (read a; echo -ne "'$a'")`
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "UPDATE users SET password = $MOR_sha1_hash WHERE id = 2" &> /dev/null
    current_user_101_password
    if [ "$?" == "0" ]; then
        report "MOR user 101 password was changed to: $GENERATED_PASSWD" 4
    else
        report "MOR user 101 password change failed" 1
    fi
else
    report "MOR user 101 password is ok" 0
fi

