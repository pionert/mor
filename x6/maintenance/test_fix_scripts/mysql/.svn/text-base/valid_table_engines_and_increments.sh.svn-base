#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks if there are any tables in MOR database using MyISAM engine and without auto increment fields using this sql stement:
#            SHOW TABLE STATUS WHERE Engine = 'myisam' or Auto_increment is null;

. /usr/src/mor/x6/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
check_for_tables_with_innodb_engine_and_without_increment()
{
    TMP_FILE=`/bin/mktemp`
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SHOW TABLE STATUS WHERE Engine = 'myisam' or Auto_increment is null;" | (read; cat) | grep -v "monitorings_users\|import_csv" | wc -l > $TMP_FILE
    if [ "$DEBUG" == "1" ]; then cat $TMP_FILE; fi
    BAD_TABLES=`cat $TMP_FILE`;
    rm -rf $TMP_FILE
    if [ "$BAD_TABLES" != "0" ]; then
        report "There a corrupted? tables in MOR DB. Some of them might have wrong engine (MyISAM instead of InnoDB) or do not have Auto_increment. Check the table below to get more information:\n\n" 1
        /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SHOW TABLE STATUS WHERE Engine = 'myisam' or Auto_increment is null;" | grep -v "monitorings_users\|import_csv"
    else
	report "There are no MyISAM tables" 0 
    fi
}
#--------MAIN -------------
apache_is_running
gui_exists
if [ "$APACHE_IS_RUNNING" == "0" ] && [ "$MOR_GUI_EXIST" == "0" ]; then
    mysql_connect_data_v2  > /dev/null
    check_for_tables_with_innodb_engine_and_without_increment
fi
