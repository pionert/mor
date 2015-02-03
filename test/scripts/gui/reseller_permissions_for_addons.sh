#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script is targeted to MOR 10 =< and checks if required permissions are available for reseller addon to work properly

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
check_if_reseller_has_all_available_permissions_which_have_to_be_set_during_upgrade_to_mor_10()
{
    # Author: Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About: checks if permissions from MOR 10 are not missing for reseller

    #[root@localhost]# mysql mor -e "select * from acc_rights where right_type = 'reseller';"
    #+----+------------------+------------------+------------------+------------+
    #| id | name             | nice_name        | permission_group | right_type |
    #+----+------------------+------------------+------------------+------------+
    #| 31 | calling_cards    | Calling_Cards    | Plugins          | reseller   |
    #| 32 | call_shop        | Call_Shop        | Plugins          | reseller   |
    #| 33 | sms_addon        | SMS              | Plugins          | reseller   |
    #| 34 | payment_gateways | Payment_Gateways | Plugins          | reseller   |
    #| 35 | monitorings      | Monitorings      | Plugins          | reseller   |   # FROM MOR 11
    #+----+------------------+------------------+------------------+------------+


    mysql_connect_data_v2      > /dev/null
    if [ "$?" != "0" ]; then
        report "Failed to check if reseller has required permissions for addons. Check manually by launching this sql: select count(*) from acc_rights where right_type = 'reseller'; The result should be 4 rows with addon names." 3
    fi
    if [ "$MOR_VERSION_YOU_ARE_TESTING" == "10" ] ; then
        if [ `/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "select count(*) from acc_rights where right_type = 'reseller';" | (read; cat)` -lt "4" ]; then
            report "Upgrade to MOR 10 was not made and reseller permissions are now missing. Do upgrade to MOR 10 to fix this. Run info.sh again to test after all." 1
        fi
    else
        if [ `/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "select count(*) from acc_rights where right_type = 'reseller';" | (read; cat)` -lt "5" ]; then
            report "Upgrade to MOR 11 was not made and reseller permissions are now missing. Do upgrade to MOR 11 to fix this. Run info.sh again to test after all." 1
        fi
    fi
}


#--------MAIN -------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

apache_is_running
if [ "$?" != "0" ]; then
    exit 0
fi

mor_gui_current_version
mor_version_mapper "$MOR_VERSION_YOU_ARE_TESTING"

if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "100" ] ; then
    check_if_reseller_has_all_available_permissions_which_have_to_be_set_during_upgrade_to_mor_10
fi
