#! /bin/sh
#==== Includes=====================================
   cd /usr/src/mor
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================

# get db data
mysql_connect_data


echo "Syncing data"

# 8.5mln calls (Query took 763.9761 sec) be careful!

/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" "$DB_NAME" -e "UPDATE calls JOIN dids ON dids.id = calls.did_id SET calls.dst_user_id = dids.user_id WHERE calls.did_id > 0;"    

echo "Data sync complete"
