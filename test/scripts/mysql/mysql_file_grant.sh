#! /bin/sh
#
#   Author: Mindaugas Mardosas, Nerijus Sapola
#   Year:   2012
#   About:  This script checks if MySQL FILE GRANT is present. IF not - tries to fix it.

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh

read_mor_gui_settings       # don't comment out checking for gui - because we need that GUI MySQL user would have this grant.
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

apache_is_running   # mysql_connect_data_v2 must take data from GUI config, so apache must be running.
if [ "$?" != "0" ]; then
    exit 0
fi

mysql_connect_data_v2

if [ `/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "show grants" | grep "*.*" | grep FILE | wc -l` == 1 ] || [ `/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "show grants" | grep "*.*" | grep ALL | wc -l` == 1 ]; then
    report "MySQL FILE Grant is OK" 0
else
    if [ "$DB_HOST" == "localhost" ] || [ "$DB_HOST" == "127.0.0.1" ]; then
        report "Now will attempt to fix MySQL FILE GRANT problem for MOR user. You might be requested to provide MySQL root password" 3
        mysql -u root -e "GRANT FILE ON *.* TO 'mor'@'localhost'; FLUSH PRIVILEGES;"
        if [ `/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "show grants" | grep "*.*" | grep FILE | wc -l` == 1 ] || [ `/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "show grants" | grep "*.*" | grep ALL | wc -l` == 1 ]; then
            report "MySQL FILE Grant was fixed" 4
            exit 0
        else
            report "FAILED to fix MySQL FILE Grant on local database." 1
            exit 1
        fi
    else
        report "Cannot fix MySQL FILE Grant, because database is on remote server. Please connect to database server and Grant FILE permission to GUI MySQL user. Syntax: GRANT FILE ON *.* TO 'mor'@'IP_OF_GUI_SERVER';" 1
        exit 1
    fi
fi
exit 0
