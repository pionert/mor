#! /bin/sh
#
# Author:   Mindaugas Mardosas
# Year:     2013
# About:    This script checks if tests are stuck and if so - restarts them
#
# Crontab for this script:
#
#   echo "*/1 * * * * root sh /usr/src/mor/test/test_monitor.sh" > /etc/cron.d/test_monitor


#==== Functions ===========

check_if_tests_are_stuck()
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
    
    if [ `tail -n 10 /var/log/mor/test_system | grep "Another test is already running" | wc -l` -ge  "10" ]; then
        STUCK=1
        return 1  # tests are stuck
    else
        STUCK=0
        return 0  # tests are not stuck
    fi
}

#======== Main ==================


check_if_tests_are_stuck

if [ "$STUCK" == "1" ]; then
    echo "Detected that tests are stuck, launching recovery script: /usr/src/mor/test/restart_tests.sh" >> /var/log/mor/test_system
    /usr/src/mor/test/restart_tests.sh
fi
