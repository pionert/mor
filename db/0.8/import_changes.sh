#! /bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================
#clear

# get db data
mysql_connect_data

echo "Importing Permissions"

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/0.8/permissions.sql

echo "Importing Hangup Cause Codes"

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/hangupcausecodes.sql

#echo
echo "Importing STRUCTURE Changes"

FILE="/usr/src/mor/db/0.8/beta_structure.sql"
exec < $FILE
while read LINE
do
  mysql_sql "$LINE"
done

#echo
echo "Importing DATA Changes"

/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" < /usr/src/mor/db/0.8/beta_data.sql

#==== Importing new permissions dump
/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" < /usr/src/mor/db/0.8/permissions_8.sql    


