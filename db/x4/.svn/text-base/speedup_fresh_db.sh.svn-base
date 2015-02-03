#! /bin/sh
#==== Includes=====================================
   cd /usr/src/mor
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================


# Use this script only for fresh DB!!!!
# if it fails at some point (maybe index not exist) - report to Kolmisoft so it can be fixed 



# get db data
mysql_connect_data


echo "DB optimization starting"

#/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/x4/speedup.sql

FILE="/usr/src/mor/db/x4/speedup.sql"
exec < $FILE
while read LINE
do
  mysql_sql "$LINE"
done

echo "DB optimization complete"
