#! /bin/sh

# Author:   Mindaugas Mardosas, Nerijus Sapola
# Company:  Kolmisoft
# Year:     2012
# About:    MOR Billing platform settings reading/writing framework

. /usr/src/mor/x5/framework/bash_functions.sh
        
read_mor_binlog_setting()
{
    #   Author: Mindaugas Mardosas, Nerijus Sapola
    #   Year:   2012
    #   About:  This function checks if binlog is configured by administrator to be enabled on this system
    #
    #   Returns:
    #       0   - NO, MySQL binlog should not be enabled on this server
    #       1   - YES, MySQL binlog has  to be enabled on this server
    #
    #       Also returns a global variable BINLOG_SETTING which can be used later in scripts to check if MySQL binlog has to enabled

    if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print \$1}' /etc/mor/system.conf | grep BINLOG | wc -l` == 1 ]; then
        BINLOG_SETTING=`awk -F"#" '{print \$1}' /etc/mor/system.conf | grep "BINLOG=1" | wc -l`
    fi
    return $BINLOG_SETTING
}

read_mor_replication_settings()
{
    #   Author: Mindaugas Mardosas, Nerijus Sapola
    #   Year:   2012
    #   About:  This function reads replication settings
    #
    #   Returns:
    #       REPLICATION_M - {0 - disabled; 1 - enabled}
    #       REPLICATION_S - {0 - disabled; 1 - enabled}
    #       DB_MASTER_MASTER - {"yes", "no" }
    #       DB_SLAVE  - {"yes", "no" }
    #       REPLICATION_PRESENT - { "yes", "no" }   

    if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print \$1}' /etc/mor/system.conf | grep "REPLICATION_M\|REPLICATION_S" | wc -l` == "2" ]; then
        REPLICATION_M=`awk -F"#" '{print $1}' /etc/mor/system.conf | grep REPLICATION_M | awk -F"=" '{print $2}'`
        REPLICATION_S=`awk -F"#" '{print $1}' /etc/mor/system.conf | grep REPLICATION_S | awk -F"=" '{print $2}'`
    fi

    #===================DB_MASTER_MASTER
    if [ "$REPLICATION_M" == "1" ] && [ "$REPLICATION_S" == "1" ]; then
        DB_MASTER_MASTER="yes"
    else
        DB_MASTER_MASTER="no"
    fi

    #===================REPLICATION_PRESENT

    if [ "$REPLICATION_M" == "1" ] || [ "$REPLICATION_S" == "1" ]; then
        REPLICATION_PRESENT="yes"
    else
        REPLICATION_PRESENT="no"
    fi

    #===================DB_SLAVE
    if [ "$REPLICATION_S" == "1" ]; then
        DB_SLAVE="yes"
    else
        DB_SLAVE="no"
    fi
}

read_mor_gui_settings()
{
    #   Author: Nerijus Sapola
    #   Year:   2012
    #   About:  This function reads GUI settings
    #
    #   Returns:
    #       GUI_PRESENT - {0 - GUI should not be running on server; 1 - GUI should be running on server}

    if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "GUI_PRESENT" | wc -l` == "1" ]; then
        GUI_PRESENT=`awk -F"#" '{print $1}' /etc/mor/system.conf | grep GUI_PRESENT | awk -F"=" '{print $2}'`
    else
        # checking if values are not duplicated
        if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "GUI_PRESENT" | wc -l` -gt "1" ]; then
            report "Duplicated values on /etc/mor/system.conf, please fix manually" 1
            exit 1
        fi
    fi
    return $GUI_PRESENT
}

read_mor_asterisk_settings()
{
    #   Author: Nerijus Sapola
    #   Year:   2012
    #   About:  This function reads Asterisk settings
    #
    #   Returns:
    #       ASTERISK_PRESENT - {0 - Asterisk should not be running on server; 1 - Asterisk should be running on server}

    if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "ASTERISK_PRESENT" | wc -l` == "1" ]; then
        ASTERISK_PRESENT=`awk -F"#" '{print $1}' /etc/mor/system.conf | grep ASTERISK_PRESENT | awk -F"=" '{print $2}'`
    else
        # checking if values are not duplicated
        if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "ASTERISK_PRESENT" | wc -l` -gt "1" ]; then
            report "Duplicated values on /etc/mor/system.conf, please fix manually" 1
            exit 1
        fi
    fi
    return $ASTERISK_PRESENT
}

read_mor_db_settings()
{
    #   Author: Nerijus Sapola
    #   Year:   2012
    #   About:  This function reads Asterisk settings
    #
    #   Returns:
    #       DB_PRESENT - {0 - MOR Database should not be running on server; 1 - MOR Database should be running on server}

    if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "DB_PRESENT" | wc -l` == "1" ]; then
        DB_PRESENT=`awk -F"#" '{print $1}' /etc/mor/system.conf | grep DB_PRESENT | awk -F"=" '{print $2}'`
    else
        # checking if values are not duplicated
        if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "DB_PRESENT" | wc -l` -gt "1" ]; then
            report "Duplicated values on /etc/mor/system.conf, please fix manually" 1
            exit 1
        fi
    fi
    return $DB_PRESENT
}

read_mor_scripts_settings()
{
    # If MAIN_DB=1 in system conf, it means that DB related scripts (aggregates, alerts, background tasks) should be running
  
    #   Returns:
    #       MAIN_DB_PRESENT - {0 - DB related scripts should NOT be running on server; 
    #                  1 - DB related scripts should be running on server;
    #                  2 - MAIN_DB is not in definied system.conf

    if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "MAIN_DB" | wc -l` == "1" ]; then
        MAIN_DB_PRESENT=`awk -F"#" '{print $1}' /etc/mor/system.conf | grep MAIN_DB | awk -F"=" '{print $2}'`
        
    elif [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "MAIN_DB" | wc -l` == "0" ]; then
        MAIN_DB_PRESENT=2
            
    # checking if values are not duplicated
    elif [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "MAIN_DB" | wc -l` -gt "1" ]; then
        report "Duplicated values on /etc/mor/system.conf, please fix manually" 1
        exit 1
        
    fi
    return $MAIN_DB_PRESENT
}
