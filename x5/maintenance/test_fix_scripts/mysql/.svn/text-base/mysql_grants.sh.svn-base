#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This script is responsible for adding various MySQL grants (permissions for mor user)

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh
. /usr/src/mor/x5/framework/mysql_specific_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

read_mor_db_settings
if [ "$DB_PRESENT" == "0" ]; then
    exit 0;
fi

mysql_connect_data_v2  &> /dev/null

GRANT_ADDING_FAILED="FALSE"

mysql_check_add_grant "PROCESS"
if [ "GRANT_IS_PRESENT" == "1" ]; then
    GRANT_ADDING_FAILED="TRUE"
fi

mysql_check_add_grant "SUPER"
if [ "GRANT_IS_PRESENT" == "1" ]; then
    GRANT_ADDING_FAILED="TRUE"
fi

mysql_check_add_grant "FILE"
if [ "GRANT_IS_PRESENT" == "1" ]; then
    GRANT_ADDING_FAILED="TRUE"
fi

#----- END ------

if [ "$GRANT_ADDING_FAILED" = "TRUE" ]; then
	report "Failed to add one or more MySQL permission grants. Please run this script manually to debug: sh -x $0" 1
	exit 1
else
    report "MySQL permission grants ok" 0
fi