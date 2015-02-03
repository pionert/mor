#/bin/bash

# Author: gm
# This script checks if db related scripts supposed to be running here

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

list_crons_and_scripts()
{
    #simply lists which db related crons and services are active
    
    local cron_name
    local service_name
    
    
    for cron_name in "/etc/cron.d/mor_aggregates_control" "/etc/cron.d/mor_delete_old_rates" "/etc/cron.d/mor_background_tasks"
    do
    
        if [ -f $cron_name ]; then
            report "$cron_name exists" 3
        else
            report "$cron_name does not exist" 3
        fi
    done
    
    for service_name in "mor_alerts" "mor_aggregates" "mor_server_loadstats"
    do
        service $service_name status | grep running >/dev/null
           #service is running
           if [ $? == '0' ]; then
               report "$service_name service is running" 3
           else
               report "$service_name service is NOT running" 3
           fi
    done
}


check_scripts_crons()
{
    # Author: gilbertas matusevicius
    # String arrays in Bash is  painful
    # This aproach seems to be the most readable
       
    local SHOULDBE=$1
    local cron_name
    local cron_name_basename
    
    for cron_name in "/etc/cron.d/mor_aggregates_control" "/etc/cron.d/mor_delete_old_rates" "/etc/cron.d/mor_background_tasks"
    do
    
        if [ -f $cron_name ]; then
            #cron exists
            if [ $SHOULDBE == "0" ]; then
                report "$cron_name should NOT be here. DELETING" 3
                rm -f $cron_name
            else
                report "$cron_name exists" 0
            fi
        else
           #cron do NOT exists
           if [ $SHOULDBE == "0" ]; then
                report "$cron_name is NOT present here" 0
           else
                report "$cron_name is NOT present here, but it should be here. ENABLING it" 3
                cron_name_basename=$(basename $cron_name)
                cp -f "/usr/src/mor/x5/scripts/cronjobs/$cron_name_basename" "/etc/cron.d"
           fi
       fi
    done
    
}

check_scripts_services()
{
   
    local SHOULDBE=$1
    local service_name
    
    for service_name in "mor_alerts" "mor_aggregates"
    do
        service $service_name status | grep running >/dev/null
           #service is running
           if [ $? == '0' ]; then
               if [ $SHOULDBE == "0" ] ; then
                   report "$service_name should NOT be running here. DISABLING" 3
                   service $service_name stop
                   chkconfig --level 2345 $service_name off
               else
                   report "$service_name is running here" 0
               fi
           else 
               #service is not running
               if [ $SHOULDBE == "0" ] ; then
                   report "$service_name service is not running here" 0
               else
                   report "$service_name service is NOT running here, but it SHOULD be here. ENABLING it" 3
                   cp -f /usr/src/mor/x5/scripts/"$service_name"_service "/etc/init.d/$service_name"
                   chmod 777 "/etc/init.d/$service_name"
                   chkconfig --add $service_name
                   chkconfig --level 2345 $service_name on
                   service $service_name start
               fi
           fi
    done
} 
    
        


check_scripts()
{

    read_mor_db_settings
    read_mor_replication_settings
    read_mor_scripts_settings
    
    #  Db related scripts/crons should be running if either:
    #  1) DB is present and no replication is present
    #  2) DB is present and Master replication is  present and MAIN_DB=1 in /etc/system.conf
    #  3) DB is  present and Master replication is present and there is no MAIN_DB_PRESENT variable in /etc/system.conf
    #     This means that /etc/system.conf was not updated with MAIN_DB variable and we do not know if this is main or not main DB
    #     So compile everything (as we did before  MAIN_DB  was introduced), but emit a warning about this
    
    
    if [ $DB_PRESENT == "1" ]
    then  
        # 1) case
        if [ "$REPLICATION_PRESENT" == "no" ]; then
            report "Simple DB is present without replication.  DB related scripts should be running here. I will check and fix this if needed" 3
            check_scripts_crons "1"
            check_scripts_services "1"
            
        
        # 2) case
        elif  [ "$REPLICATION_M" == "1" ] && [ $MAIN_DB_PRESENT == "1" ]; then
            report "DB Master replication is present and MAIN_DB=1 here. DB related scripts should be running here. I will check and fix this if needed" 3
            check_scripts_crons "1"
            check_scripts_services "1"
            
        # 3) case
        elif  [ "$REPLICATION_M" == "1" ] && [ $MAIN_DB_PRESENT == "2" ]; then
            report "DB master replication is running on this server, but no information about MAIN_DB is found in system.conf file" 2
            report "Please update information in /etc/system.conf related to MAIN_DB status and run minf again" 2
            report "I will do nothing here, beause I do not know if this is MAIN DB or not !!!" 2
            report "Here is the status of scripts:" 2
            list_crons_and_scripts
            
            
         
        # This is not MAIN DB. Bye bye scripts
        
        elif  [ "$REPLICATION_M" == "1" ] && [ $MAIN_DB_PRESENT == "0" ]; then
            report "DB master replication is present BUT this is NOT MAIN DB server.  DB related scripts should NOT be running here. I will check and fix this if needed" 3
            check_scripts_crons "0"
            check_scripts_services "0"  
        
        fi
    else
        #DB IS NOT present here, bye bye scripts
        report "DB is NOT present here.  DB related scripts should NOT be running here. I will check and fix this if needed" 3
        check_scripts_crons "0"
        check_scripts_services "0"
        
    fi
}

check_scripts

