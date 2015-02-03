#! /bin/sh
#==== Includes=====================================
   cd /usr/src/mor
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================

/usr/src/mor/test/scripts/mysql/mysql_grants.sh

echo "Running /usr/src/mor/db/12.126/import_changes.sh"

echo "Importing STRUCTURE Changes"
mysql_connect_data # get db data

FILE="/usr/src/mor/db/12.126/beta_structure.sql"
exec < $FILE
while read LINE
do
  mysql_sql "$LINE"
done

echo "Importing DATA Changes"

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/12.126/beta_data.sql

echo "Data imported"


echo "Importing Currency Changes"
/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/12.126/currency_changes.sql
echo "Currency changes import complete"

#==== Importing new permissions dump

echo "Importing permissions"

/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" < /usr/src/mor/db/12.126/permissions.sql


echo "Permissions imported"

echo "DB upgrade complete"
