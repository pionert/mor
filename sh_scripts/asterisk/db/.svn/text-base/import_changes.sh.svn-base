#! /bin/sh
#==== Includes=====================================
   cd /usr/src/mor
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh

#==================================================
#clear

# get db data
mysql_connect_data

#echo "Importing Permissions"

#/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/0.8/permissions.sql

#echo
echo "Importing STRUCTURE Changes"

FILE="/usr/src/mor/sh_scripts/asterisk/db/beta_structure.sql"
exec < $FILE
while read LINE
do
  mysql_sql "$LINE"
done

echo
echo "Importing DATA Changes"

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/sh_scripts/asterisk/db/beta_data.sql

echo "Importing Triggers"
/usr/bin/mysql -h "$DB_HOST" -u root --password="" "$DB_NAME" < /usr/src/mor/sh_scripts/asterisk/db/triggers.sql
if [ "$?" != "0" ]; then    #if inserting without a password fails
    /usr/bin/mysql -h "$DB_HOST" -u root -p  "$DB_NAME" < /usr/src/mor/sh_scripts/asterisk/db/triggers.sql
fi