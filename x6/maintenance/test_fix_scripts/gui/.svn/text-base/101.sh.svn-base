#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
check_if_101_device_has_default_pass()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks if 101 device still has a default password

    # Returns:
    #   0   -   OK, password is not default
    #   1   -   FAILED, password is left default
    
    mysql_connect_data_v2  &> /dev/null
    if [ "$?" == "1" ]; then
        report "Failed to check if user 101 device has default password" 1
        exit 1;
    fi

    TMP_FILE=`/bin/mktemp`

    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT secret FROM devices WHERE secret='101'" | (read; cat) | head -n 1 > $TMP_FILE
    key=`cat $TMP_FILE`;
    rm -rf $TMP_FILE

    if [ "$key" == "101" ]; then
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

check_if_101_device_has_default_pass
if [ "$?" == "1" ]; then
    generate_random_password 20
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "UPDATE devices SET secret = '$GENERATED_PASSWD' WHERE secret='101'" &> /dev/null
    check_if_101_device_has_default_pass
    if [ "$?" == "0" ]; then
        report "101 device password was weak and changed to: $GENERATED_PASSWD" 4
    else
        report "Failed to fix 101 device weak password, do that manually!" 4
    fi
else
    report "Device 101 is secure" 0
fi
