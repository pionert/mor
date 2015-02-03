#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script creates a hardly guessable password

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#------VARIABLES-------------


#----- FUNCTIONS ------------
current_admin_password()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks current MOR GUI admin password.
    #   Returns:
    #       0  password is not equal "admin"
    #       1  password is default "admin"
    #   Other notes:
    #       This function depends on function mysql_connect_data_v2

    CURRENT_MOR_GUI_PASSWORD=`/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT password FROM users WHERE id = 0 AND usertype = 'admin'"  | (read; cat)` &> /dev/null

    if [ "$CURRENT_MOR_GUI_PASSWORD" == "d033e22ae348aeb5660fc2140aec35850c4da997" ]; then
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
current_admin_password
if [ "$?" != "0" ]; then
    generate_random_password 12
    MOR_sha1_hash=`echo -n $GENERATED_PASSWD | sha1sum | awk '{ print $1}' | (read a; echo -ne "'$a'")`
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "UPDATE users SET password = $MOR_sha1_hash WHERE id = 0 AND usertype = 'admin'" &> /dev/null
    current_admin_password
    if [ "$?" == "0" ]; then
        report "MOR GUI admin password was changed to: $GENERATED_PASSWD" 6
    else
        report "MOR GUI admin password change failed" 1
    fi
else
    report "MOR GUI admin password is ok" 0
fi
