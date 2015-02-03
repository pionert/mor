#!/bin/sh

. /usr/src/mor/test/framework/bash_functions.sh

asterisk_current_version #gives $ASTERISK_BRANCH variable

mkdir -p /usr/local/mor

cd /usr/src/mor/scripts

rm -rf mor_ast_register
gcc -I/usr/include/mysql mor_ast_register.c -o mor_ast_register -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_ast_register /usr/local/mor

if [ "$ASTERISK_BRANCH" == "1.8" ]; then
    /bin/cp -fr /usr/src/mor/sh_scripts/asterisk/scripts/mor_ast_generate_ivr.c /usr/src/mor/scripts/
fi

rm -rf mor_ast_generate_ivr
gcc -I/usr/include/mysql mor_ast_generate_ivr.c -o mor_ast_generate_ivr -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_ast_generate_ivr /usr/local/mor

rm -rf mor_ast_h323
gcc -I/usr/include/mysql mor_ast_h323.c -o mor_ast_h323 -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_ast_h323 /usr/local/mor

rm -rf mor_ast_sip
gcc -I/usr/include/mysql mor_ast_sip.c -o mor_ast_sip -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_ast_sip /usr/local/mor

rm -rf mor_record_file
gcc -I/usr/include/mysql mor_record_file.c -o mor_record_file -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_record_file /usr/local/mor

rm -rf mor_record_remote
gcc -I/usr/include/mysql mor_record_remote.c -o mor_record_remote -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_record_remote /usr/local/mor

rm -rf mor_record_control
gcc -I/usr/include/mysql mor_record_control.c -o mor_record_control -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_record_control /usr/local/mor

rm -rf mor_send_email_api
gcc -I/usr/include/mysql mor_send_email_api.c -o mor_send_email_api -lcurl -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_send_email_api /usr/local/mor

rm -rf mor_ast_device_subnet
gcc -Wall -g -o mor_ast_device_subnet mor_ast_device_subnet.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient
cp -fr mor_ast_device_subnet /usr/local/mor/

rm -rf mor_archive_old_calls
gcc -Wall -o mor_archive_old_calls mor_archive_old_calls.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient -lpthread -lm
cp -fr mor_archive_old_calls /usr/local/mor/

rm -rf m2_background_tasks
gcc -Wall -g -o m2_background_tasks m2_background_tasks.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient
cp -fr m2_background_tasks /usr/local/mor/

rm -rf mor_blacklisting_script
gcc -o mor_blacklisting_script mor_blacklisting_script.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient
cp -fr mor_blacklisting_script /usr/local/mor/

if [ ! -e /usr/local/mor/blacklist.conf ]; then
	cp -fr blacklist.conf /usr/local/mor
fi

rm -rf mor_provider_check
gcc -o mor_provider_check mor_provider_check.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient -lpthread
cp -fr mor_provider_check /usr/local/mor/

# mor_server_loadstats recompile and service reinstall
killall -9 mor_server_loadstats &> /dev/null
gcc -o mor_server_loadstats mor_server_loadstats.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient -lpthread
cp -fr mor_server_loadstats /usr/local/mor/mor_server_loadstats

cp -fr mor_server_loadstats_service /etc/init.d/mor_server_loadstats
chmod +x /etc/init.d/mor_server_loadstats
chkconfig --add mor_server_loadstats
chkconfig --level 2345 mor_server_loadstats on
service mor_server_loadstats start &> /dev/null

rm -rf mor_queues
gcc -o mor_queues mor_queues.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient
cp -fr mor_queues /usr/local/mor/

rm -rf mor_extensions_queues
gcc -o mor_extensions_queues mor_extensions_queues.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient
cp -fr mor_extensions_queues /usr/local/mor/

rm -rf mor_musiconhold
gcc -o mor_musiconhold mor_musiconhold.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient
cp -fr mor_musiconhold /usr/local/mor/

service mor_alerts stop &> /dev/null
killall -9 mor_alerts &> /dev/null

gcc -Wall -o mor_alerts mor_alerts.c -lcurl -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_alerts /usr/local/mor/mor_alerts

cp -fr mor_alerts_service /etc/init.d/mor_alerts
chmod 777 /etc/init.d/mor_alerts
chkconfig --add mor_alerts
chkconfig --level 2345 mor_alerts on
service mor_alerts start &> /dev/null

chmod 777 -R /var/log/mor/
