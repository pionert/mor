#! /bin/bash
#   Author: Mindaugas Mardosas
#   Year:   2012
#   About:  This script temporary allows a support engineer to access magento admin panel


MAGENTO_INSTALL_DIR="$1"

. /usr/src/mor/test/framework/bash_functions.sh

if [ ! -d "$MAGENTO_INSTALL_DIR" ]; then
    report "Your provided Magento installation directory: $MAGENTO_INSTALL_DIR does not exist, exiting" 1
    exit 1
fi

if [ ! -f "/usr/bin/xmlstarlet" ]; then
    report "/usr/bin/xmlstarlet not installed" 1
    exit 1
fi

wait_user2() {   echo -e "\nPress enter to continue\n\n"; read; echo -e "\n\n"; }

magento_mysql_connect_data()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function gets magento installation database settings
    
    DATABASE_username=`xmlstarlet sel -t -v //config/global/resources/default_setup/connection/username $MAGENTO_INSTALL_DIR/app/etc/local.xml 2> /dev/null`
    DATABASE_password=`xmlstarlet sel -t -v //config/global/resources/default_setup/connection/password $MAGENTO_INSTALL_DIR/app/etc/local.xml 2> /dev/null`
    DATABASE_DB_NAME=`xmlstarlet sel -t -v //config/global/resources/default_setup/connection/dbname $MAGENTO_INSTALL_DIR/app/etc/local.xml 2> /dev/null`
    DATABASE_host=`xmlstarlet sel -t -v //config/global/resources/default_setup/connection/host $MAGENTO_INSTALL_DIR/app/etc/local.xml 2> /dev/null`
}


magento_admin_pass_crack()
{
    # if arg 1 is passed - the script executes that command or other script (the gui login/pass then will be admin/admin)

    if [ -f "$MAGENTO_INSTALL_DIR/magento_gui_admin_pass_hash" ]; then echo -e "\E[31m$MAGENTO_INSTALL_DIR/magento_gui_admin_pass_hash found, please correct your mistakes manually, I won't overwrite user's pass hash backup\E[37m]"; return 1; fi
    magento_mysql_connect_data; &> /dev/null
    if [ $? == 1 ]; then
            echo "Failed to get database data, exiting..";
            return 1;
    fi
    #==================================
    current_pass=`/usr/bin/mysql -h "$DATABASE_host" -u $DATABASE_username --password=$DATABASE_password "$DATABASE_DB_NAME" -e "SELECT password FROM admin_user WHERE user_id='1';" | sed -n '2,2 p'`                    #backing up the current user password hash
    current_username=`/usr/bin/mysql -h "$DATABASE_host" -u $DATABASE_username --password=$DATABASE_password "$DATABASE_DB_NAME" -e "SELECT username FROM admin_user WHERE user_id = '1';" | sed -n '2,2 p'`
    echo -ne "$current_username\n$current_pass\n">> $MAGENTO_INSTALL_DIR/magento_gui_admin_pass_hash; 
    if [ $? != 0 ]; then
            echo "Failed to get the current admin username or pass";
            return 1;
    fi
    /usr/bin/mysql -h "$DATABASE_host" -u $DATABASE_username --password=$DATABASE_password "$DATABASE_DB_NAME" -e  "UPDATE admin_user SET username = 'magento_admin', password = '32e7b74335a5b0a1e9c96c3879332c97:aa' WHERE user_id = 1"
    if [ $? != 0 ]; then
        echo "Failed to set default username or pass";
        return 1;
    fi
    #--- Get URL where admin should connect

    local magento_url=`/usr/bin/mysql -h "$DATABASE_host" -u $DATABASE_username --password=$DATABASE_password "$DATABASE_DB_NAME" -e  "SELECT value FROM core_config_data WHERE config_id = 4;"  | sed -n '2,2 p'`
    echo -ne "\nURL to access magento admin panel:\n\n$magento_url"admin"\n\n\nUsername: magento_admin\nPassword: magento_admin\n\n\n"
    #-----
    wait_user2
    /usr/bin/mysql -h "$DATABASE_host" -u $DATABASE_username --password=$DATABASE_password "$DATABASE_DB_NAME" -e  "UPDATE admin_user SET username = '$current_username', password = '$current_pass' WHERE user_id = 1"
    if [ $? != 0 ]; then
        echo -e "Failed to restore the original username or pass, you can find the original user pass hash in:\n $MAGENTO_INSTALL_DIR/mor_gui_admin_username and $MAGENTO_INSTALL_DIR/magento_gui_admin_pass_hash"
        return 1;
    fi
    echo -e "Original username and pass has been restored\nCleaned the mess.."         
    rm -rf $MAGENTO_INSTALL_DIR/magento_gui_admin_pass_hash
    return 0
}

magento_admin_pass_crack
