#! /bin/sh
#
# Author:   Mindaugas Mardosas
# Year:     2013
# About:    This script checks if zabbix_server is allive. Restarts if needed

#
# Crontab for this script:
#
#   echo "*/5 * * * * root sh /usr/src/mor/test/zabbix_monitor.sh" > /etc/cron.d/zabbix_monitor


#==== Functions ===========

check_if_zabbix_server_running()
{
    # Author:   Mindaugas Mardosas
    # Year:     2013
    # About:    This function checks if tests are stuck
    #
    # Returns:
    #   1   -   Failure, tests are really stuck
    #   0   -   OK. Tests are running normally
    #
    #   Global variable:
    #       STUCK {0, 1}
    
    if [ `ps aux | grep zabbix_server | grep -v grep | wc -l` == "0" ]; then
        STUCK=1
        return 1  
    else
        STUCK=0
        return 0  # 
    fi
}

#======== Main ==================


check_if_zabbix_server_running

if [ "$STUCK" == "1" ]; then
    mkdir -p /var/log/mor
    echo "Detected that tests are stuck, launching recovery script: /usr/src/mor/test/restart_tests.sh" >> /var/log/mor/zabbix_server
    zabbix_server restart
fi
