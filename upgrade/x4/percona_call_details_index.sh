#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    This script is responsible for adding call_id_index for call_details table

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh


#------VARIABLES-------------
NO_SCREEN="$1"  # Option to be tolerant on running without screen

BACKUP_PATH="$2"

if [ ! -d "$BACKUP_PATH" ]; then
    BACKUP_PATH="/home"
fi


if [ "$NO_SCREEN" != "NO_SCREEN" ]; then
    are_we_inside_screen
    if [ "$?" == "1" ]; then
        report "You have to run this script from 'screen' program. To do so - just run command 'screen' and launch the script again as usual"   1
        exit 1
    fi
fi
#----- FUNCTIONS ------------
#--------MAIN -------------
mysql_connect_data_v2      > /dev/null

/usr/src/mor/sh_scripts/percona_install.sh
if [ "$?" != "0" ]; then
    exit 1
fi

check_if_db_index_present call_details call_id_index
if [ "$?" == "0" ]; then	# If index not present
    /usr/src/mor/test/scripts/mysql/mysql_grants.sh
    if [ "$?" != "0" ]; then
        exit 1;
    fi

	dump_mor_db "$BACKUP_PATH"

	report "Now Percona will add index for call_details table" 3
    pt-online-schema-change --host "$DB_HOST" --user "$DB_USERNAME" --password "$DB_PASSWORD" --execute --alter "ADD INDEX call_id_index (call_id)" D="$DB_NAME",t=call_details
    status="$?"
	if [ "$status" == "0" ]; then
	    report "call_details table percona migration was successful" 0
	else
	    report "Failed to migrate call_details table with percona. You can find DB backup in /home dir if needed." 1
	fi
fi