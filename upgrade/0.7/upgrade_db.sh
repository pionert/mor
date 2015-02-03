#! /bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh

#==================================================
#clear

# get db data
mysql_connect_data

echo -e "\n-------- Starting MOR database upgrade to v0.7 ----------\n"
echo -e "\n--------- Making backup ---------\n"
   mysqldump -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" --single-transaction "$DB_NAME" > /usr/src/mor/upgrade/0.7/backup/mor_backup.$$.sql ; 
   if [ $? != 0 ]; then echo "Database upgrade failed"; fi;
						                        
#compressing....
cd /usr/src/mor/upgrade/0.7/backup/
tar -czf mor_backup.$$.sql.tar.gz mor_backup.$$.sql
rm -rf mor_backup.$$.sql 


echo -e "done.\n --------- Upgrading tables ---------\n"


/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/upgrade/0.7/upgrade_db_tables.sql

echo -e "done.\n---------- Altering tables ------------\n"

mysql_sql "ALTER TABLE conflines ADD value2 BLOB DEFAULT NULL;"
mysql_sql "ALTER TABLE devices ADD COLUMN temporary_id integer DEFAULT NULL;"
mysql_sql "ALTER TABLE users ADD COLUMN temporary_id integer DEFAULT NULL;"
mysql_sql "ALTER TABLE currencies ADD COLUMN curr_update int(11) default 1;"
mysql_sql "ALTER TABLE currencies ADD COLUMN curr_edit int(11) default 1;"
mysql_sql "ALTER TABLE services ADD COLUMN owner_id int(11) default 0;"
mysql_sql "ALTER TABLE calls ADD COLUMN did_inc_price double DEFAULT 0;"
mysql_sql "ALTER TABLE calls ADD COLUMN did_prov_price double DEFAULT 0;"
mysql_sql "ALTER TABLE calls ADD COLUMN localized_dst varchar(50) default NULL;"
mysql_sql "ALTER TABLE dids ADD COLUMN comment varchar(255) default NULL;"
mysql_sql "ALTER TABLE users ADD COLUMN send_invoice_types int(11) default 1;"

mysql_sql "ALTER TABLE devices ADD COLUMN allow_duplicate_calls int(11) DEFAULT 0;"
mysql_sql "ALTER TABLE c2c_campaigns ADD try_times int(11) default 3;"
mysql_sql "ALTER TABLE c2c_campaigns ADD pause_between_calls int(11) default 20;"
mysql_sql "ALTER TABLE services ADD quantity int(11) default 1;"

mysql_sql "ALTER TABLE users ADD call_limit int(11) default '0';"
mysql_sql "ALTER TABLE devices ADD call_limit int(11) default '0';"
mysql_sql "ALTER TABLE providers ADD call_limit int(11) default '0';"

mysql_sql "ALTER TABLE providers ADD COLUMN interpret_noanswer_as_failed tinyint(4) DEFAULT 0;"
mysql_sql "ALTER TABLE providers ADD COLUMN interpret_busy_as_failed tinyint(4) DEFAULT 0;"

mysql_sql "ALTER TABLE servers ADD port int(11) default '5060';"
mysql_sql "ALTER TABLE c2c_calls ADD notice_email_send int(11) default '0';"
mysql_sql "ALTER TABLE c2c_campaigns ADD send_email_after int(11) default '60';"
mysql_sql "ALTER TABLE users ADD c2c_call_price double default NULL;"

mysql_sql "ALTER TABLE dids ADD call_limit int(11) default '0';"

mysql_sql "ALTER TABLE activecalls ADD did_id int(11) default NULL;"
mysql_sql "ALTER TABLE activecalls ADD user_id int(11) default NULL;"
mysql_sql "ALTER TABLE activecalls ADD owner_id int(11) default NULL;"
mysql_sql "ALTER TABLE activecalls ADD prefix varchar(255) default NULL;"

mysql_sql "ALTER TABLE locationrules ADD lcr_id int(11) default NULL;"
mysql_sql "ALTER TABLE locationrules ADD tariff_id int(11) default NULL;"

mysql_sql "ALTER TABLE servers ADD ssh_username varchar(255) default 'root';"
mysql_sql "ALTER TABLE servers ADD ssh_secret varchar(255) default NULL;"
mysql_sql "ALTER TABLE servers ADD ssh_port int(11) default '22';"
mysql_sql "ALTER TABLE users ADD sms_tariff_id int(11) default NULL;"
mysql_sql "ALTER TABLE users ADD sms_lcr_id int(11) default NULL;"
mysql_sql "ALTER TABLE users ADD sms_service_active int(11) default '0';"

mysql_sql "ALTER TABLE calls ADD did_provider_id int(11) default 0;"
mysql_sql "ALTER TABLE users ADD cyberplat_active INT(1) DEFAULT 0;"
mysql_sql "ALTER TABLE providers ADD register INT(1) DEFAULT 0;"
mysql_sql "ALTER TABLE providers ADD reg_extension varchar(30) DEFAULT NULL;"
mysql_sql "ALTER TABLE c2c_invoicedetails ADD quantity INT(11) default '0';"
mysql_sql "ALTER TABLE calls ADD COLUMN did_id int(11) DEFAULT NULL;"
mysql_sql "ALTER TABLE emails ADD format varchar(255) default 'html';"

mysql_sql "ALTER TABLE invoices ADD sent_email INT(11)  default '0';"
mysql_sql "ALTER TABLE invoices ADD sent_manually INT(11)  default '0';"
mysql_sql "ALTER TABLE c2c_invoices ADD sent_email INT(11)  default '0';"
mysql_sql "ALTER TABLE c2c_invoices ADD sent_manually INT(11)  default '0';"

mysql_sql "ALTER TABLE callflows ADD data3 int(11) default '1';"
mysql_sql "ALTER TABLE callflows ADD data4 varchar(255) default null;"

mysql_sql "ALTER TABLE actions ADD processed INT(11) default '0';"

mysql_sql "ALTER TABLE activecalls ADD localized_dst varchar(100) default NULL;"

mysql_sql "ALTER TABLE emails ADD owner_id INT(11)  default '0';"
mysql_sql "ALTER TABLE emails ADD callcenter INT(11)  default '0';"

mysql_sql "ALTER TABLE hangupcausecodes CHANGE description description BLOB NOT NULL;"

mysql_sql "ALTER TABLE users ADD call_center_agent INT(11)  default '0';"

mysql_sql "ALTER TABLE campaigns ADD callerid varchar(100)  default '';"

mysql_sql "ALTER TABLE emails ADD template tinyint(4) default 0;"

mysql_sql "CREATE INDEX cards_number_index ON cards(number);"
mysql_sql "CREATE INDEX cards_pin_index ON cards(pin);"


mysql_sql "ALTER TABLE cardgroups ADD owner_id INT(11)  default '0';"

# --- indexes ---
mysql_sql "CREATE INDEX destinations_direction_code_index ON destinations(direction_code);"
mysql_sql "CREATE INDEX directions_code_index ON directions (code);"
mysql_sql "CREATE INDEX dt USING BTREE ON ratedetails(daytype);"
mysql_sql "CREATE INDEX ad1 USING BTREE ON adnumbers(status, campaign_id);"
mysql_sql "CREATE INDEX name USING BTREE ON currencies(name);"
mysql_sql "CREATE INDEX periodstart USING BTREE ON invoices(period_start);"
mysql_sql "CREATE INDEX disposition USING BTREE ON calls(disposition);"
mysql_sql "CREATE INDEX user_id_index ON subscriptions(user_id);"
mysql_sql "CREATE INDEX user_id_index ON calls(user_id);"
mysql_sql "CREATE INDEX hgcause ON calls(hangupcause);"
mysql_sql "CREATE INDEX calldate ON calls(calldate, src_device_id, dst_device_id);"

mysql_sql "ALTER TABLE conflines DROP KEY uname;"

mysql_sql "ALTER TABLE \`calls\` DROP INDEX \`7\`, DROP INDEX \`3\`, DROP INDEX \`2\`, DROP INDEX \`9\`, DROP INDEX \`4\`, DROP INDEX \`5\`, DROP INDEX \`id\`, DROP INDEX \`calldate_2\`, DROP INDEX \`calldate_3\`, DROP INDEX \`dst\`, DROP INDEX \`dst_2\`;"


mysql_sql "ALTER TABLE devices ADD lastms int(11) default 0;"

#/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD -e "USE mor; "

if [ $VERBOSE == 1 ]; then
   echo -e "\nDON'T PANIC!!!\n"
   echo "NOTE: ERROR 1060 means that field is allready in DB and it is not added - you can ignore this error message."
   echo "NOTE: ERROR 1061 means that key is allready in DB and it is not added - you can ignore this error message."
   echo "NOTE: ERROR 1091 means that column/key is allready deleted - you can ignore this error message."
fi;

echo -e "\ndone.\n\n-------- Inserting new values ----------\n"

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/upgrade/0.7/upgrade_db_data.sql

/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/upgrade/0.7/upgrade_db_currencies.sql
/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/db/hangupcausecodes.sql
/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < /usr/src/mor/upgrade/0.7/upgrade_db_permissions.sql

#mysql_sql "UPDATE conflines SET value = 'MOR 0.7' WHERE name = 'Version' AND owner_id = 0;"

mysql_sql "UPDATE conflines SET value = '/usr/local/mor/backups' WHERE name = 'Backup_Folder';"

echo -e "done.\n-------- MOR database upgraded ----------\n\n"

