#! /bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh

#==================================================
clear

echo "Running this script will completely remove your DATABASE (INCLUDING USERS, CALLS ...), press ENTER to continue or CTRL+C to abort"
read

# get db data
mysql_connect_data

#echo

#if [ "$1" == "nobk" ]; then
 
# echo "No DB backup will be made..."

#else

  echo -e "Making backup"
     mysqldump -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" --single-transaction "$DB_NAME" > /usr/src/mor/db/0.8/backup/mor_backup.$$.sql ; 
     if [ $? != 0 ]; then echo "Database upgrade failed"; fi;
						                        
  #compressing....
  cd /usr/src/mor/db/0.8/backup/
  tar -czf mor_backup.$$.sql.tar.gz mor_backup.$$.sql
  rm -rf mor_backup.$$.sql 

#fi

#echo
echo "Importing clean DB for MOR 8"

cd /usr/src/mor/db/0.8/
extract_gz mor8db.tgz

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD < /usr/src/mor/db/0.8/init.sql
/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/0.8/mor8.sql

cd /usr/src/mor/db/0.8/
./import_changes.sh

#echo
echo "New DB for MOR 8 prepared"
