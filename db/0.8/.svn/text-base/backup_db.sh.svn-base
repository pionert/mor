#! /bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh

#==================================================
#clear

# get db data
mysql_connect_data


  echo -e "Making DB backup, please wait..."
     mysqldump -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" --single-transaction "$DB_NAME" > /usr/src/mor/db/0.8/backup/mor_backup.$$.sql ; 
     if [ $? != 0 ]; then echo "Database upgrade failed"; fi;
						                        
  #compressing....
  cd /usr/src/mor/db/0.8/backup/
  tar -czf mor_backup.$$.sql.tar.gz mor_backup.$$.sql
  rm -rf mor_backup.$$.sql 


echo "DB backup complete!"
