#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This script collects data required by programmers to solve bugs.
#
# Arguments:
#	$1	-	How many days back from now calls table is needed?
#	$2 	-	Ticket number

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

HOW_MANY_DAYS_CALLS_ARE_NEEDED="$1"
TICKER_NUMBER="$2"
NO_SCREEN="$3"  # Option to be tolerant on running without screen

if [ "$HOW_MANY_DAYS_CALLS_ARE_NEEDED" == "" ] || [ "$TICKER_NUMBER" == "" ]; then
	report "Invalid command line arguments" 1
	echo -e "\n1 parameter: number of days calls history is needed. If you will specify 0 here - no dump will be made\n2 parameter - TRAC ticket number or other fraze which will be used as file name."
	exit 1
fi

if [ "$NO_SCREEN" != "NO_SCREEN" ]; then    # require to be running from screen from now on
    are_we_inside_screen
    if [ "$?" == "1" ]; then
        report "You have to run this script from 'screen' program. To do so - just run command 'screen' and launch the script again as usual"   1
        exit 1
    fi
fi


UPLOAD_SERVER="dev.kolmisoft.com"
UPLOAD_PORT="6666"
UPLOAD_PATH="/home/support/DB"

#----- FUNCTIONS ------------

dump_db_without_calls()
{
# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This function

	mysqldump --single-transaction -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" --ignore-table="$DB_NAME".calls --ignore-table="$DB_NAME".call_logs --ignore-table="$DB_NAME".call_details --ignore-table="$DB_NAME".calls_old --ignore-table="$DB_NAME".bl_dst_scoring --ignore-table="$DB_NAME".bl_src_scoring --ignore-table="$DB_NAME".bl_ip_scoring --ignore-table="$DB_NAME".time_periods --ignore-table="$DB_NAME".aggregates --ignore-table="$DB_NAME".server_loadstats > /home/.tmp_dir_for_mor_data_gathering/mor_db_without_calls.sql

	if [ "$?" == "0" ]; then
		report "Created DB backup: /home/.tmp_dir_for_mor_data_gathering/mor_db_without_calls.sql" 3
	else
		report "Failed to create DB backup: /home/.tmp_dir_for_mor_data_gathering/mor_db_without_calls.sql. Exiting script." 1
		cleanup_mess
		exit 1
	fi
}
dump_calls_table()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	# About:	This function dumps call table only for specified time period

	local days_to_dump_from_now="$1"

	current_date=`date +%Y-%m-%-d`

	date_from=`date -d "$current_date -$days_to_dump_from_now days" +%Y-%m-%d`

	mysqldump --single-transaction -h "$DB_HOST" -u "$DB_USERNAME" --password=$DB_PASSWORD "$DB_NAME" calls --where="calldate between '$date_from 00:00:00' and '$current_date 00:00:00'" > /home/.tmp_dir_for_mor_data_gathering/mor_db_calls_only.sql
	if [ "$?" == "0" ]; then
		report "Created DB backup: /home/.tmp_dir_for_mor_data_gathering/mor_db_calls_only.sql" 3
	else
		report "Failed to create DB backup: /home/.tmp_dir_for_mor_data_gathering/mor_db_calls_only.sql. Exiting script." 1
		cleanup_mess
		exit 1
	fi
}

compress_data()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	# About:	This function compress all data in order it would be sent to Kolmisoft server.

	cd /home/.tmp_dir_for_mor_data_gathering
	if [ -f "mor_db_calls_only.sql" ]; then
		tar czf $TICKER_NUMBER.tar.gz mor_db_calls_only.sql mor_db_without_calls.sql
	else	# compressing DB without calls
		tar czf $TICKER_NUMBER.tar.gz mor_db_without_calls.sql
	fi

	if [ "$?" == "0" ]; then
		report "Successfully compressed the database to /home/.tmp_dir_for_mor_data_gathering/$TICKER_NUMBER.tar.gz" 3
	else
		report "Failed to compress database. Exiting script" 1
		cleanup_mess
		exit 1
	fi
}

cleanup_mess()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	# About:	This function cleans all temporary data created during data gathering

	rm -rf /home/.tmp_dir_for_mor_data_gathering
	report "Cleaned out temporary dir at /home/.tmp_dir_for_mor_data_gathering" 3
}

upload_archive()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft-
	# Year:     2013
	# About:	This function uploads collected data to Kolmisoft development server

	 scp -P 6666 /home/.tmp_dir_for_mor_data_gathering/"$TICKER_NUMBER".tar.gz support@"$UPLOAD_SERVER":"$UPLOAD_PATH/$TICKER_NUMBER.tar.gz"
	 if [ "$?" == "0" ]; then
	 	report "Data archive was Successfully uploaded" 3
	 else
		report "Failed to upload data archive" 1
	 fi
}

#--------MAIN -------------
mysql_connect_data_v2      > /dev/null	# Getting MySQL connect data

mkdir -p /home/.tmp_dir_for_mor_data_gathering
dump_db_without_calls

if [ "$HOW_MANY_DAYS_CALLS_ARE_NEEDED" != "0" ]; then
	dump_calls_table "$HOW_MANY_DAYS_CALLS_ARE_NEEDED"
fi
compress_data
upload_archive

#--------------------------
cleanup_mess