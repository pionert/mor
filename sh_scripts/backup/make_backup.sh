#! /bin/bash

#====================================
# execution: /bin/sh  /your_path/make_backup.sh arg1 arg2
#  arg1 here stands for date in YYYYMMDDHHIISS format
#  arg2 here stands for full backup location path
#  arg3 "-c" if you need to compress all the archives
#====================================

. /usr/local/mor/mor_install_functions.sh
. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh
   

   


   _DATE=$1;
   _BACKUP_FOLDER=$2;

    # check for params

    if [ ! -n "$1" ] && [ ! -n "$2" ]; then
	echo arguments not passed;
	echo -n `date` >> $_LOG;
	echo "arguments not passed" >> $_LOG
	echo 1;
	exit 1;
    fi;


    # get db data and..?

    #mysql_connect_data
    #backups_error_output mysql_connect_data
    mysql_connect_data_v2      > /dev/null

    # make backup

    cd $_BACKUP_FOLDER;
    echo "Backing up the mor db";
    mysqldump -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD --single-transaction --ignore-table="$DB_NAME".backups "$DB_NAME" > "$_BACKUP_FOLDER"/db_dump_"$_DATE".sql;
    if [ "$?" != "0" ]; then
        echo 1;
        exit 1;
    fi

    # compress backup

    cd $_BACKUP_FOLDER;
    mor_compress db_dump_"$_DATE".sql 1
    if [ "$?" != "0" ]; then
        echo 1;
        exit 1;
    fi

    if [ -f "$_BACKUP_FOLDER"/db_dump_"$_DATE".sql.tar.gz ]; then
        echo "Backup successfully created: $_BACKUP_FOLDER/db_dump_$_DATE.sql.tar.gz" >> /tmp/mor_debug_backup.txt
        echo 0;
        exit 0;
    else
        echo "Backup FAILED"  >> /tmp/mor_debug_backup.txt
        echo 1;
        exit 1;
    fi

