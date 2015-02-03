#! /bin/sh
#==== Includes=====================================
   cd /usr/src/mor
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================

# get db data
mysql_connect_data

echo "Importing STRUCTURE Changes"

FILE="/usr/src/mor/db/11/beta_structure.sql"
exec < $FILE
while read LINE
do
  mysql_sql "$LINE"
done

echo "Importing DATA Changes"

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/11/beta_data.sql

echo "Data imported"

#==== Importing new permissions dump

echo "Importing permissions"

/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" < /usr/src/mor/db/11/permissions.sql


echo "Permissions imported"

echo "DB upgrade complete"
