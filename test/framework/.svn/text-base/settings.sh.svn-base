#! /bin/sh

# Author:   Mindaugas Mardosas, Nerijus Sapola
# Company:  Kolmisoft
# Year:     2012
# About:    MOR Billing platform settings reading/writing framework

. /usr/src/mor/test/framework/bash_functions.sh
        
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
    
    if [ -f /etc/mor/db.conf ] && [ `awk -F"#" '{print \$1}' /etc/mor/db.conf | grep BINLOG | wc -l` == 1 ]; then
        BINLOG_SETTING=`awk -F"#" '{print \$1}' /etc/mor/db.conf | grep "BINLOG=1" | wc -l`
    else
        mkdir -p /etc/mor
        get_answer "MySQL binlog setting is not present on this server. Should MySQL binlog be enabled on this server (Should be enabled if you are going to build MySQL replication or client modifies his DB himself)?" "y"
        
        if [ "$answer" == "y" ]; then
            echo "BINLOG=1" >> /etc/mor/db.conf
            BINLOG_SETTING=1
        else
            echo "BINLOG=0" >> /etc/mor/db.conf
            BINLOG_SETTING=0
        fi
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
        
    if [ -f /etc/mor/db.conf ] && [ `awk -F"#" '{print \$1}' /etc/mor/db.conf | grep "REPLICATION_M\|REPLICATION_S" | wc -l` == "2" ]; then
        REPLICATION_M=`awk -F"#" '{print $1}' /etc/mor/db.conf | grep REPLICATION_M | awk -F"=" '{print $2}'`
        REPLICATION_S=`awk -F"#" '{print $1}' /etc/mor/db.conf | grep REPLICATION_S | awk -F"=" '{print $2}'`
    elif [ -f /etc/mor/db.conf ] && [ `awk -F"#" '{print \$1}' /etc/mor/db.conf | grep "REPLICATION_M\|REPLICATION_S" | wc -l` == "0" ]; then
    # asking user for correct configuration
        mkdir -p /etc/mor
        get_answer "Is this server participating in DB replication?" "n"
        
        if [ "$answer" == "y" ]; then
            get_answer "Is it Master<>Master replication" "y"
            if [ "$answer" == "y" ]; then
                REPLICATION_M=1
                REPLICATION_S=1
                echo -e "REPLICATION_M=1\nREPLICATION_S=1" >> /etc/mor/db.conf 
            else
                get_answer "Is it Master server" "y"
                if [ "$answer" == "y" ]; then
                    REPLICATION_M=1
                    REPLICATION_S=0
                    echo -e "REPLICATION_M=1\nREPLICATION_S=0" >> /etc/mor/db.conf
                else
                    echo "According previous answers this server is Slave"
                    REPLICATION_M=0
                    REPLICATION_S=1
                    echo -e "REPLICATION_M=0\nREPLICATION_S=1" >> /etc/mor/db.conf
                fi
            fi
        else
            REPLICATION_M=0
            REPLICATION_S=0
            echo -e "REPLICATION_M=0\nREPLICATION_S=0" >> /etc/mor/db.conf
        fi
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

    # backwards compatibility support for new X5 install which uses /etc/mor/system.conf
    if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "GUI_PRESENT" | wc -l` == "1" ]; then
        GUI_PRESENT=`awk -F"#" '{print $1}' /etc/mor/system.conf | grep GUI_PRESENT | awk -F"=" '{print $2}'`
        return $GUI_PRESENT
    else
        # checking if values are not duplicated
        if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "GUI_PRESENT" | wc -l` -gt "1" ]; then
            report "Duplicated values on /etc/mor/system.conf, please fix manually" 1
            exit 1
        fi
    fi

        
    if [ -f /etc/mor/gui.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/gui.conf | grep "GUI_PRESENT" | wc -l` == "1" ]; then
        GUI_PRESENT=`awk -F"#" '{print $1}' /etc/mor/gui.conf | grep GUI_PRESENT | awk -F"=" '{print $2}'`
    else
        # checking if values are not duplicated
        if [ -f /etc/mor/gui.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/gui.conf | grep "GUI_PRESENT" | wc -l` -gt "1" ]; then
            report "Duplicated values on /etc/mor/gui.conf, please fix manually" 1
            exit 1
        fi
        
        # asking user for correct configuration
        mkdir -p /etc/mor
  
        get_answer "Is GUI present on this server?" "y"
    
        if [ "$answer" == "y" ]; then
            GUI_PRESENT=1
            echo "GUI_PRESENT=1" >> /etc/mor/gui.conf
        else
            GUI_PRESENT=0
            echo "GUI_PRESENT=0" >> /etc/mor/gui.conf
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

    # backwards compatibility support for new X5 install which uses /etc/mor/system.conf
    if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "ASTERISK_PRESENT" | wc -l` == "1" ]; then
        ASTERISK_PRESENT=`awk -F"#" '{print $1}' /etc/mor/system.conf | grep ASTERISK_PRESENT | awk -F"=" '{print $2}'`
	return $ASTERISK_PRESENT
    else
        # checking if values are not duplicated
        if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "ASTERISK_PRESENT" | wc -l` -gt "1" ]; then
            report "Duplicated values on /etc/mor/system.conf, please fix manually" 1
            exit 1
        fi
    fi

        
    if [ -f /etc/mor/asterisk.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/asterisk.conf | grep "ASTERISK_PRESENT" | wc -l` == "1" ]; then
        ASTERISK_PRESENT=`awk -F"#" '{print $1}' /etc/mor/asterisk.conf | grep ASTERISK_PRESENT | awk -F"=" '{print $2}'`
    else
        # checking if values are not duplicated
        if [ -f /etc/mor/asterisk.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/asterisk.conf | grep "ASTERISK_PRESENT" | wc -l` -gt "1" ]; then
            report "Duplicated values on /etc/mor/asterisk.conf, please fix manually" 1
            exit 1
        fi
        
        # asking user for correct configuration
        mkdir -p /etc/mor
  
        get_answer "Is ASTERISK present on this server?" "y"

        if [ "$answer" == "y" ]; then
            ASTERISK_PRESENT=1
            echo "ASTERISK_PRESENT=1" >> /etc/mor/asterisk.conf
        else
            ASTERISK_PRESENT=0
            echo "ASTERISK_PRESENT=0" >> /etc/mor/asterisk.conf
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

    # backwards compatibility support for new X5 install which uses /etc/mor/system.conf
    if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "DB_PRESENT" | wc -l` == "1" ]; then
        DB_PRESENT=`awk -F"#" '{print $1}' /etc/mor/system.conf | grep DB_PRESENT | awk -F"=" '{print $2}'`
        return $DB_PRESENT
    else
        # checking if values are not duplicated
        if [ -f /etc/mor/system.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/system.conf | grep "DB_PRESENT" | wc -l` -gt "1" ]; then
            report "Duplicated values on /etc/mor/system.conf, please fix manually" 1
            exit 1
        fi
    fi

    if [ -f /etc/mor/db.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/db.conf | grep "DB_PRESENT" | wc -l` == "1" ]; then
        DB_PRESENT=`awk -F"#" '{print $1}' /etc/mor/db.conf | grep DB_PRESENT | awk -F"=" '{print $2}'`
    else
        # checking if values are not duplicated
        if [ -f /etc/mor/db.conf ] && [ `awk -F"#" '{print $1}' /etc/mor/db.conf | grep "DB_PRESENT" | wc -l` -gt "1" ]; then
            report "Duplicated values on /etc/mor/db.conf, please fix manually" 1
            exit 1
        fi
        
        # asking user for correct configuration
        mkdir -p /etc/mor
  
        get_answer "Is MOR DATABASE present on this server?" "y"
    
        if [ "$answer" == "y" ]; then
            DB_PRESENT=1
            echo "DB_PRESENT=1" >> /etc/mor/db.conf
        else
            DB_PRESENT=0
            echo "DB_PRESENT=0" >> /etc/mor/db.conf
            if [ -z `awk -F"#" '{print $1}' /etc/mor/db.conf | grep "REPLICATION_S"` ] && [ -z `awk -F"#" '{print $1}' /etc/mor/db.conf | grep "REPLICATION_M"` ]; then
                REPLICATION_M=0
                REPLICATION_S=0
                echo -e "REPLICATION_M=0\nREPLICATION_S=0" >> /etc/mor/db.conf
            fi
        fi
    fi
    return $DB_PRESENT
}
