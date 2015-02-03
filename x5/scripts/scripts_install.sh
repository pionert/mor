#!/bin/sh

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh


report "Starting Script update" 3

if [ "$1" == "LATEST" ]; then
  report "Updating Scripts to LATEST revision" 3
  svn update /usr/src/mor/x5/scripts
else
  stable_rev=`cat /usr/src/mor/x5/stable_revision`
  report "Updating Scripts to STABLE revision: $stable_rev" 3
  cd /usr/src/mor/x5/scripts
  svn -r $stable_rev update
  svn update /usr/src/mor/x5/scripts/scripts_install.sh
fi

mkdir -p /usr/local/mor
mkdir -p /var/log/mor
mkdir -p /tmp/mor
chmod 777 -R /var/log/mor
chmod 777 /tmp/mor

cd /usr/src/mor/x5/scripts

# delete old scripts
rm -fr /usr/local/mor/m2_background_tasks &> /dev/null
rm -fr /usr/local/mor/m2_cdr_rerate &> /dev/null
rm -fr /usr/local/mor/m2_aggregates &> /dev/null
rm -fr /usr/local/mor/m2_aggregates_control &> /dev/null
rm -fr /usr/local/mor/m2_archive_old_calls &> /dev/null
rm -fr /usr/local/mor/m2_invoices &> /dev/null
rm -fr /usr/local/mor/m2_invoices_report &> /dev/null
rm -fr /usr/local/mor/m2_tariff_generator &> /dev/null
rm -fr /usr/local/mor/m2_server_loadstats &> /dev/null

# kill running old scripts
killall -9 m2_aggregates &> /dev/null
killall -9 m2_alerts &> /dev/null
killall -9 m2_server_loadstats &> /dev/null

# remove old scripts from startup
chkconfig --del m2_alerts &> /dev/null
chkconfig --del m2_aggregates &> /dev/null
chkconfig --del m2_server_loadstats &> /dev/null

# remove old script from other places
rm -fr /etc/init.d/m2_aggregates &> /dev/null
rm -fr /etc/init.d/m2_alerts &> /dev/null
rm -fr /etc/init.d/m2_server_loadstats &> /dev/null
rm -fr /etc/cron.d/m2_aggregates &> /dev/null
rm -fr /etc/cron.d/m2_alerts &> /dev/null
rm -fr /etc/cron.d/m2_server_loadstats &> /dev/null



db_scripts_recompile()
{
     service mor_alerts stop &> /dev/null
     killall -9 mor_alerts &> /dev/null

     gcc -Wall -o mor_alerts mor_alerts.c -lcurl -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
     cp -fr mor_alerts /usr/local/mor/mor_alerts
     chmod 777 /usr/local/mor/mor_alerts

     cp -fr mor_alerts_service /etc/init.d/mor_alerts
     chmod 777 /etc/init.d/mor_alerts
     chkconfig --add mor_alerts
     chkconfig --level 2345 mor_alerts on
     /etc/init.d/mor_alerts start

     rm -rf mor_cdr_rerate
     gcc -Wall -o mor_cdr_rerate mor_cdr_rerate.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient
     cp -fr mor_cdr_rerate /usr/local/mor/
     chmod 777 /usr/local/mor/mor_cdr_rerate

     service mor_aggregates stop &> /dev/null
     killall -9 mor_aggregates &> /dev/null
     killall -9 mor_aggregates_control &> /dev/null

     gcc -Wall -g -o mor_aggregates mor_aggregates.c mor_aggregates.h -lcurl -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
     cp -fr mor_aggregates /usr/local/mor/mor_aggregates
     chmod 777 /usr/local/mor/mor_aggregates

     cp -fr mor_aggregates_service /etc/init.d/mor_aggregates
     chmod 777 /etc/init.d/mor_aggregates
     chkconfig --add mor_aggregates
     chkconfig --level 2345 mor_aggregates on
     /etc/init.d/mor_aggregates start

     gcc -Wall -g -o mor_aggregates_control mor_aggregates_control.c mor_aggregates.h -lcurl -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
     cp -fr mor_aggregates_control /usr/local/mor/mor_aggregates_control
     chmod 777 /usr/local/mor/mor_aggregates_control

     rm -rf mor_delete_old_rates
     gcc -Wall -o mor_delete_old_rates mor_delete_old_rates.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient -lpthread -lm
     cp -fr mor_delete_old_rates /usr/local/mor/mor_delete_old_rates
     chmod 777 /usr/local/mor/mor_delete_old_rates

     rm -rf mor_archive_old_calls
     gcc -Wall -o mor_archive_old_calls mor_archive_old_calls.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient -lpthread -lm
     cp -fr mor_archive_old_calls /usr/local/mor/

     rm -rf mor_background_tasks
     gcc -Wall -g -o mor_background_tasks mor_background_tasks.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient
     cp -fr mor_background_tasks /usr/local/mor/

     rm -rf mor_blacklisting_script
     gcc -Wall -o mor_blacklisting_script mor_blacklisting_script.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient
     cp -fr mor_blacklisting_script /usr/local/mor/

     if [ ! -e /usr/local/mor/blacklist.conf ]; then # TODO move to /etc/mor
	cp -fr blacklist.conf /usr/local/mor
     fi

     # install db related cronjobs
     cp -fr /usr/src/mor/x5/scripts/cronjobs/mor_aggregates_control /etc/cron.d/
     cp -fr /usr/src/mor/x5/scripts/cronjobs/mor_delete_old_rates /etc/cron.d/
     cp -fr /usr/src/mor/x5/scripts/cronjobs/mor_background_tasks /etc/cron.d/
     
     # Keep alive crons
     cp -fr /usr/src/mor/x5/scripts/cronjobs/keep_aggregates_alive /etc/cron.d/
     cp -fr /usr/src/mor/x5/scripts/cronjobs/keep_alerts_alive /etc/cron.d/

     /etc/init.d/crond restart &> /dev/null

}

check_db_scripts()
{

    read_mor_db_settings
    read_mor_replication_settings
    read_mor_scripts_settings

    # We should compile end enable db related scripts/crons if either:
    #  1) DB is present and no replication is present
    #  2) DB is present and Master replication is present and MAIN_DB=1 in /etc/system.conf
    #  3) DB is present and Master replication is present and there is no MAIN_DB_PRESENT variable in /etc/system.conf
    #     This means that /etc/system.conf was not updated with MAIN_DB variable and we do not know if this is main or not main DB
    #     So compile everything (as we did before MAIN_DB_PRESENT was introduced), but emit a warning about this

    if [ $DB_PRESENT == "1" ]; then

        # 1) case
        if [ "$REPLICATION_PRESENT" == "no" ]
        then
            report "Simple DB is present without replication. Recompilng and enabling DB related scripts" 3
            db_scripts_recompile

        # 2) case
        elif  [ "$REPLICATION_M" == "1" ] && [ $MAIN_DB_PRESENT == "1" ]; then
            report "DB Master replication is enbaled MAIN_DB=1 here. Recompilng and enabling DB related scripts" 3
            db_scripts_recompile
        # 3) case
        elif  [ "$REPLICATION_M" == "1" ] && [ $MAIN_DB_PRESENT == "2" ]; then
            report "DB master replication is running on this server, but no information about MAIN_DB is found in system.conf file" 2
            report "Recompiling and enabling DB related scripts which may cause issues" 2
            report "Please update information in /etc/system.conf related to MAIN_DB status" 2
            db_scripts_recompile
        fi

    #No scripts is needed
    else
        report "DB related scripts will NOT be recompiled or enabled. Either DB is not present or this is not main DB" 3
    fi
}

check_db_scripts

#install other cronjobs



#mor_minute_actions is deleted by minf (/usr/src/mor/x5/test_fix_scripts/asterisk/mor_minute_actions.sh) if it is not needed.
cp -fr /usr/src/mor/x5/scripts/cronjobs/mor_minute_actions  /etc/cron.d/

# TODO: Autodialer Should be only on one asterisk server, no?

cp -fr /usr/src/mor/x5/scripts/cronjobs/mor_auto_dialer /etc/cron.d/

# TODO this is not related to C scripts, it should deal with these cronjobs somewhere else

cp -fr /usr/src/mor/x5/scripts/cronjobs/mor_daily_actions /etc/cron.d/

cp -fr /usr/src/mor/x5/scripts/cronjobs/mor_sms_ad /etc/cron.d/



rm -rf mor_ad_cron
gcc -o mor_ad_cron mor_ad_cron.c  -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient -lpthread -lm
cp -fr mor_ad_cron /usr/local/mor/mor_ad_cron
chmod 777 /usr/local/mor/mor_ad_cron

rm -rf mor_ast_register
gcc -Wall -g -I/usr/include/mysql mor_ast_register.c -o mor_ast_register -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_ast_register /usr/local/mor

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

rm -rf mor_ast_skype
gcc -I/usr/include/mysql mor_ast_skype.c -o mor_ast_skype -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_ast_skype /usr/local/mor

rm -rf mor_send_email_api
gcc -I/usr/include/mysql mor_send_email_api.c -o mor_send_email_api -lcurl -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_send_email_api /usr/local/mor

rm -rf mor_ast_device_subnet
gcc -Wall -g -o mor_ast_device_subnet mor_ast_device_subnet.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient
cp -fr mor_ast_device_subnet /usr/local/mor/





rm -rf mor_provider_check
gcc -Wall -o mor_provider_check mor_provider_check.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient -lpthread
cp -fr mor_provider_check /usr/local/mor/

killall -9 mor_server_loadstats &> /dev/null
gcc -Wall -g -o mor_server_loadstats mor_server_loadstats.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient -lpthread
cp -fr mor_server_loadstats /usr/local/mor/mor_server_loadstats

cp -fr mor_server_loadstats_service /etc/init.d/mor_server_loadstats
chmod +x /etc/init.d/mor_server_loadstats
chkconfig --add mor_server_loadstats
chkconfig --level 2345 mor_server_loadstats on
service mor_server_loadstats start &> /dev/null

rm -rf mor_queues
gcc -Wall -o mor_queues mor_queues.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient
cp -fr mor_queues /usr/local/mor/

rm -rf mor_extensions_queues
gcc -Wall -o mor_extensions_queues mor_extensions_queues.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient
cp -fr mor_extensions_queues /usr/local/mor/

rm -rf mor_musiconhold
gcc -Wall -o mor_musiconhold mor_musiconhold.c -L/usr/lib/mysql -L/usr/lib64/mysql -lmysqlclient
cp -fr mor_musiconhold /usr/local/mor/



#sendEmail
cp -fr sendEmail /usr/local/mor
cp -fr sendEmail /bin

# backup scripts
mkdir -p /usr/local/mor/backups
chmod 777 /usr/local/mor/backups
cp -fr /usr/src/mor/x5/scripts/backups/* /usr/local/mor/backups

# ---
cp -u  /usr/src/mor/x5/scripts/mor_wav2mp3 /bin/
cp -fr /usr/src/mor/x5/scripts/convert_mp3wav2astwav.sh /usr/local/mor

report "Script update completed" 0
