#! /bin/bash
# Author:	Mindaugas Mardosas
# Year:		2013
# About:	This script is responsible for loading DB backups into database.
#
# Cron:
#
#	echo '*/1 * * * * root /usr/src/mor/test/db_loader/db_cron_manager.sh' > /etc/cron.d/db_manager
create_lock()
{
	touch /dev/shm/db_loader_lock
}
delete_lock()
{
	rm -rf /dev/shm/db_loader_lock
}
check_if_there_are_new_db_requests()
{
	# Author:	Mindaugas Mardosas
	# Year:		2013
	# About:	This function is responsible for checking if there are new DB requests.
	#
	# Returns:
	#	0	-	there are no new db requests
	#	1	-	there are new db requests

	mkdir -p /dev/shm/db_load_requests # preventing errors when DB does not exist

	if [ `ls -1 /dev/shm/db_load_requests | wc -l` == "0" ]; then
		delete_lock
		NEW_REQUESTS=0
		exit 0	# There are no new request - just exiting
	else
		NEW_REQUESTS=1
		if [ ! -f "/dev/shm/db_loader_lock" ]; then
			create_lock
		fi
	fi
	return $NEW_REQUESTS
}
get_job()
{
	# Author:	Mindaugas Mardosas
	# Year:		2013
	# About:	This function is responsible for getting 1 job which was created first. FIFO - first in is first served
	#
	check_if_there_are_new_db_requests
	JOB=`ls -t1 /dev/shm/db_load_requests | tail -n 1`
}
read_job()
{
	# Author:	Mindaugas Mardosas
	# Year:		2013
	# About:	This function is responsible for reading a job task
	#   
	# Arguments:
	#	$1	-	JOB name
	#
	# Returns:
	#	TASK - {IMPORT, DELETE}

	JOB_NAME="$1"
	
	TASK=`cat /dev/shm/db_load_requests/$JOB_NAME`

	if [ "$TASK" != "IMPORT" ] &&  [ "$TASK" != "DROP" ]; then
		echo "`date` Got unknown job task for #$JOB_NAME: $TASK. Deleting this task as invalid and continuing with next one." >> /home/support/DB/log 
		if [ -f "/dev/shm/db_load_requests/$JOB_NAME" ]; then # Protection to not delete whole dir when $TASK will empty string
			rm -rf /dev/shm/db_load_requests/$JOB_NAME
		fi
		continue
	fi

}
delete_job()
{
	# Author:	Mindaugas Mardosas
	# Year:		2013
	# About:	This function is responsible for deleting job task
	#
	# Arguments:
	#	$1	-	JOB name to delete

	JOB_NAME="$1"

	if [ -f "/dev/shm/db_load_requests/$JOB_NAME" ]; then
        echo -e "`date` Deleting job for #$JOB_NAME\n\n---------------------------------" >> /home/support/DB/log 
        rm -rf "/dev/shm/db_load_requests/$JOB_NAME"
	else
		echo "`date` Failed to delete job for #$JOB_NAME" >> /home/support/DB/log 	
	fi

}
extract_db()
{
	# Author:	Mindaugas Mardosas
	# Year:		2013
	# About:	This function is responsible for importing database
	#
	# Arguments:
	#	$1	-	DB name
	#
	# Cleanup if any...

	DB_NAME="$1"

	rm -rf /home/support/DB/mor_db_calls_only.sql  /home/support/DB/mor_db_without_calls.sql

	echo "`date` Extracting DB for #$DB_NAME" >> /home/support/DB/log 		
	cd /home/support/DB

	if [ -f "$DB_NAME.tar.gz" ]; then

		tar xzvf $DB_NAME.tar.gz  >> /home/support/DB/log 2>&1
		if [ "$?" == "0" ]; then
			echo "`date` Extracted DB for #$DB_NAME" >> /home/support/DB/log 	
			return 0	
		fi
	else
		echo "`date` $DB_NAME.tar.gz does not exist" >> /home/support/DB/log
	fi
	
	echo "`date` Failed to extract DB for #$DB_NAME. Exiting script" >> /home/support/DB/log
	delete_job  "$DB_NAME"
	delete_lock
	exit 1
	
}
create_database_where_vm_would_be_able_to_connect_from_anywhere()
{
	# Author:	Mindaugas Mardosas
	# Year:		2013
	# About:	This function is responsible for creating database where we would be able to import db later.
 	# Arguments:
 	#	$1	-	db name (usually this will come as trac ticket number)

 	DB_NAME="$1"

 	# check if database already exists
 	if [ `mysql -e "show databases;" | grep ^$DB_NAME$ | wc -l` == "1" ]; then
		echo "`date` DB for #$DB_NAME already exists. DROP db first in order to import it again" >> /home/support/DB/log 
		delete_job  "$DB_NAME"
		delete_lock
		#mysql -e "DROP database \`$DB_NAME\`;"
		exit 1	# exiting from program
 	fi

 	echo "`date` Creating DB for #$DB_NAME" >> /home/support/DB/log
	mysql -e "CREATE DATABASE \`$DB_NAME\` CHARACTER SET utf8; "	
	if [ "$?" == "0" ]; then
		echo "`date` DB for #$DB_NAME created" >> /home/support/DB/log
	else
		echo "`date` Failed to create DB for #$DB_NAME" >> /home/support/DB/log
		delete_job  "$DB_NAME"
		delete_lock
		exit 1
	fi
        #-------------
        
    echo "`date` Granting priviliges for #$DB_NAME  DB" >> /home/support/DB/log
	mysql -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO \`$DB_NAME\`@'%' IDENTIFIED BY '$DB_NAME' WITH GRANT OPTION;"
	if [ "$?" != "0" ]; then
		echo "`date` Failed to grant priviliges for #$DB_NAME  DB" >> /home/support/DB/log
		delete_job  "$DB_NAME"
		delete_lock
		exit 1
	fi

	if [ "$?" == "0" ]; then
		echo "`date` PRIVILEGES for #$DB_NAME DB granted" >> /home/support/DB/log
	else
		echo "`date` Failed to grant PRIVILEGES for #$DB_NAME  DB" >> /home/support/DB/log
		delete_job  "$DB_NAME"
		delete_lock
		exit 1
	fi
        
        #-------------
        
     	echo "`date` Granting priviliges for #$DB_NAME  DB" >> /home/support/DB/log
	mysql -e "grant super on *.* to \`$DB_NAME\`@'%';"

	if [ "$?" == "0" ]; then
		echo "`date` SUPER PRIVILEGES for #$DB_NAME DB granted" >> /home/support/DB/log
	else
		echo "`date` Failed to grant SUPER PRIVILEGES for #$DB_NAME  DB" >> /home/support/DB/log
		delete_job  "$DB_NAME"
		delete_lock
		exit 1
	fi        
}

import_db()
{
	# Author:	Mindaugas Mardosas
	# Year:		2013
	# About:	This function is responsible for importing database
	#
	
	DB_NAME="$1"

	create_database_where_vm_would_be_able_to_connect_from_anywhere "$DB_NAME"	# Creating database if it does not exist yet

	extract_db "$DB_NAME"

	# Doing the import

	if [ ! -f "/home/support/DB/mor_db_without_calls.sql" ]; then
		echo "`date` Support uploaded $DB_NAME.tar.gz in wrong file format. Give them this link and ask to do the task properly: http://doc.kolmisoft.com/display/kolmisoft/DB+atsiuntimas+programuotojams" >> /home/support/DB/log
		delete_job  "$DB_NAME"
		delete_lock
		exit 1
	fi

	echo "`date` Importing /home/support/DB/mor_db_without_calls.sql for #$DB_NAME" >> /home/support/DB/log
	mysql "$DB_NAME" <  /home/support/DB/mor_db_without_calls.sql >> /home/support/DB/log 2>&1
	if [ "$?" != "0" ]; then
		echo "`date` Failed to import /home/support/DB/mor_db_without_calls.sql for #$DB_NAME. Exiting script" >> /home/support/DB/log
		delete_job  "$DB_NAME"
		delete_lock
		exit 1
	fi

	if [ -f "/home/support/DB/mor_db_calls_only.sql" ]; then
		echo "`date` Import /home/support/DB/mor_db_calls_only.sql for #$DB_NAME" >> /home/support/DB/log
		mysql "$DB_NAME" <  /home/support/DB/mor_db_calls_only.sql >> /home/support/DB/log 2>&1
		if [ "$?" != "0" ]; then
			echo "`date` Failed to import /home/support/DB/mor_db_calls_only.sql for #$DB_NAME. Exiting script" >> /home/support/DB/log
			delete_job  "$DB_NAME"
			delete_lock
			exit 1
		fi
	fi

    echo "`date` Adding missing tables which were not dumped" >> /home/support/DB/log
	/usr/src/mor/test/db_loader/db_tables_append.sh "$DB_NAME"
	if [ "$?" != "0" ]; then
		echo "`date` Failed to run script: /usr/src/mor/test/prepare_db_for_intervention.sh" >> /home/support/DB/log
	fi

	echo "`date` Running: /usr/src/mor/test/prepare_db_for_intervention.sh  IKNOWWHATIDO $DB_NAME" >> /home/support/DB/log
	/usr/src/mor/test/prepare_db_for_intervention.sh "IKNOWWHATIDO" "$DB_NAME"

    echo "`date` Import for #$DB_NAME completed" >> /home/support/DB/log
        
	#cleanup
	rm -rf /home/support/DB/mor_db_calls_only.sql  /home/support/DB/mor_db_without_calls.sql
}

drop_db()
{
	# Author:	Mindaugas Mardosas
	# Year:		2013
	# About:	This function is responsible for dropping the database
	#
	# Arguments:
	#	$1 - DB Name

	DB_NAME="$1"

	echo "`date` Droping DB for #$DB_NAME" >> /home/support/DB/log
	
	mysql -e "DROP DATABASE \`$DB_NAME\`;"
	if [ "$?" == "0" ]; then
		echo "`date` DB for #$DB_NAME dropped" >> /home/support/DB/log
	else
		echo "`date` Failed to drop #$DB_NAME" >> /home/support/DB/log
	fi
}
# ------ Main ------
touch /home/support/DB/log

if [ -f "/dev/shm/db_loader_lock" ]; then
	exit 0 # Lock found - anouther import is in progress
fi


while true; do
	get_job
	read_job "$JOB"

	echo "`date` Proceeding task for #$JOB" >> /home/support/DB/log

	if [ "$TASK" == "IMPORT" ]; then
		import_db "$JOB"
	elif [ "$TASK" == "DROP" ]; then
		drop_db "$JOB"
	fi

	delete_job "$JOB"
done


#------ END OF SCRIPT, time to cleanup ------
delete_lock &> /dev/null