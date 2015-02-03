#! /bin/sh
#==== Includes=====================================
   cd /usr/src/mor
   . "$(pwd)"/sh_scripts/install_configs.sh
#==================================================

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "UPDATE calls, dids SET calls.did_id = dids.id WHERE calls.localized_dst = dids.did;"

