#! /bin/bash
#====================================
# execution: /bin/sh  /your_path/make_restore.sh arg1 arg2
#  arg1 here stands for date in YYYYMMDDHHIISS format
#  arg2 here stands for full backup location path
#====================================

   #======= includes ===========
    . /usr/local/mor/mor_install_functions.sh
    . /usr/src/mor/test/framework/bash_functions.sh
    . /usr/src/mor/test/framework/settings.sh
   #============================
   _DATE=$1;
   _BACKUP_FOLDER=$2;

   backup_folder
   if [ ! -n "$1" ] && [ ! -n "$2" ]; then
        echo arguments not passed;
        echo -n `date` >> $_LOG;
        echo "arguments not passed" >> $_LOG;
        echo 1;
        exit 1;
    fi;

    touch /tmp/mor_debug_backup.txt
    chmod 777 /tmp/mor_debug_backup.txt

    mysql_connect_data_v2      > /dev/null  

    # save current db
    cd $_BACKUP_FOLDER;
    echo "Backing up and restoring the mor db";
    mkdir -p restore

    mysqldump -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD --single-transaction --ignore-table="$DB_NAME".backups "$DB_NAME" > "$_BACKUP_FOLDER"/restore/db_dump.sql
    if [ "$?" != "0" ]; then
        echo "Failed to make a backup of current DB before restoring. DEBUG: $1 $_BACKUP_FOLDER $OUT" >> /tmp/mor_debug_backup.txt
        echo 1
        exit 1
        
    fi
    cd restore
    mor_compress db_dump.sql 1
    backups_error_output mysql_backup_when_restoring_making_another_back

    # restore old backup
    
    if [ -f "$_BACKUP_FOLDER"/db_dump_"$_DATE".sql.tar.gz ]; then
        cd $_BACKUP_FOLDER
        tar xzf db_dump_$_DATE.sql.tar.gz
        if [ "$?" == "0" ]; then
            echo Extracted backup "$_BACKUP_FOLDER"/db_dump_$_DATE.sql.tar.gz >> /tmp/mor_debug_backup.txt
        else
            echo Failed to extract backup "$_BACKUP_FOLDER"/db_dump_"$_DATE".sql.tar.gz >> /tmp/mor_debug_backup.txt
            echo 1
            exit 1
        fi
    else
        echo Backup file does not exist: "$_BACKUP_FOLDER"/db_dump_"$_DATE".sql.tar.gz >> /tmp/mor_debug_backup.txt
        echo 1
        exit 1
    fi
    
    mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < "$_BACKUP_FOLDER"/db_dump_"$_DATE".sql
    if [ "$?" == "0" ]; then
        echo Successfully imported backup "$_BACKUP_FOLDER"/db_dump_"$_DATE".sql.tar.gz >> /tmp/mor_debug_backup.txt
    else
        echo "Failed to import backup" >> /tmp/mor_debug_backup.txt
        echo 1
        exit 1
    fi

    # delete extracted sql file to save space
    rm -rf db_dump_$_DATE.sql

    #apache_restart #not needed.

    echo 0;

