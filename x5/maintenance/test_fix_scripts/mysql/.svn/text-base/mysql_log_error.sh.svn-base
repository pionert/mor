#! /bin/sh

#   Author: Mindaugas Mardosas
#   Year:   2011
#   About:  This script checks if mysql log-error=/var/lib/mysql/mysqld.log loging is enabled, if not - enables. Please leave binlog on as it helps a lot to debug MOR
#
. /usr/src/mor/x5/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

check_if_log_error_enabled()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This script checks if mysql log-error=/var/lib/mysql/mysqld.log loging is enabled
    #   
    #   Parameters:
    #       1   -   what option to check
    # 
    #   Returns:
    #       0   -   OK, enabled
    #       1   -   Failed, not enabled

    N1=`grep log-error /etc/my.cnf | wc -l`;
    if [ "$N1" -lt "1" ]; then
        return 1
    fi  
}
#--------------------------
fix_log_error()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This script adds mysql log-error=/var/lib/mysql/mysqld.log logging
    # 
    #   Returns:
    #       0   -   OK, enabled
    #       1   -   Failed, not enabled
    _mor_time;

    check_if_log_error_enabled
    if [ "$?" != "0" ]; then
        cp /etc/my.cnf /usr/local/mor/backups/my_cnf/my.cnf_$mor_time #backup    
        sed '/\[mysqld\]/a\log-error=/var/lib/mysql/mysqld.log' /etc/my.cnf > /tmp/.my.cnf
        mv /tmp/.my.cnf /etc/my.cnf
    fi


}

#===================== MAIN =============
mysql_is_running
if [ "$?" != "0" ]; then
    exit 0;
fi

check_if_log_error_enabled
if [ "$?" == "0" ]; then
    report "/etc/my.cnf log-error=/var/lib/mysql/mysqld.log ok" 0
else
    fix_log_error
    check_if_log_error_enabled
    if [ "$?" == "0" ]; then
        report "/etc/my.cnf log-error=/var/lib/mysql/mysqld.log" 4
        report "MySQLd restart is needed for the changes to take effect: /etc/init.d/mysqld restart" 6
    else
        report "/etc/my.cnf log-error=/var/lib/mysql/mysqld.log" 1
    fi
fi


