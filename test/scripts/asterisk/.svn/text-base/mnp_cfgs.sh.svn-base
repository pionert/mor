#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script fixes configurations for MNP addon

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

FIRST_INSTALL="$1"

mnp_cfg_exists()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function checks MNP configuration file exists. If not - creates it

    if [ ! -f "/usr/local/mor/mor_mnp.conf" ]; then
        mysql_connect_data_v2 > /dev/null

        local serverid=1
        if [ -f /etc/asterisk/mor.conf ]; then
            local serverid=`awk -F";" '{print $1}' /etc/asterisk/mor.conf | grep server_id | awk -F"=" '{print $2}'`
        fi
        
        echo -ne "host = $DB_HOST\ndb = mor_mnp\nuser = $DB_USERNAME\nsecret = $DB_PASSWORD\nport = 3306\nserver_id = $serverid\nshow_sql = 0\ndebug = 1\n" > /usr/local/mor/mor_mnp.conf
        report "Added MNP config: /usr/local/mor/mor_mnp.conf" 4
    else
        report "MNP config: /usr/local/mor/mor_mnp.conf" 0
    fi
}

fix_mnp()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function checks and fix configurations for mnp addon
    
    mor_core_version "EXIT_IF_NO_CORE"  # MNP has to be enabled only in servers where Asterisk is present and MOR core running
    if [ "$MOR_CORE_BRANCH" -ge "10" ]; then    #IF MOR version is 10 or higher
		    grep "NoOp(MOR starts)" /etc/asterisk/extensions_mor.conf &> /dev/null
		    if [ "$?" == "0" ]; then
		        local temp=`/bin/mktemp`
		        sed 's!exten.*=>.*_X.,1,NoOp(MOR.*starts)!exten => _X.,1,AGI(mor_mnp)!' /etc/asterisk/extensions_mor.conf > $temp
		        mkdir -p /usr/local/mor/backups/etc/asterisk/
		        _mor_time
		        mv /etc/asterisk/extensions_mor.conf /etc/asterisk/extensions_mor.conf_$mor_time
		        mv $temp /etc/asterisk/extensions_mor.conf 
		        grep "exten => _X.,1,AGI(mor_mnp)" /etc/asterisk/extensions_mor.conf &> /dev/null
		        if [ "$?" == "0" ]; then
		            report "Reloading Asterisk extensions" 3
		            asterisk -rx "dialplan reload"
		            return 4
		        else
		            return 1
		        fi
		    else
		        return 0
		    fi

#		else #MNP not enabled in env
#		    grep "exten => _X.,1,AGI(mor_mnp)" /etc/asterisk/extensions_mor.conf &> /dev/null
#		    if [ "$?" == "0" ]; then
#		        local temp=`/bin/mktemp`
#		        sed 's!exten => _X.,1,AGI(mor_mnp)!exten => _X.,1,NoOp(MOR starts)!' /etc/asterisk/extensions_mor.conf > $temp
#		        mkdir -p /usr/local/mor/backups/etc/asterisk/
#		        _mor_time
#		        mv /etc/asterisk/extensions_mor.conf /etc/asterisk/extensions_mor.conf_$mor_time
#		        mv $temp /etc/asterisk/extensions_mor.conf 
#		        grep "exten => _X.,1,NoOp(MOR starts)" /etc/asterisk/extensions_mor.conf &> /dev/null
#		        if [ "$?" == "0" ]; then
#		            report "Reloading Asterisk extensions" 3
#		            asterisk -rx "dialplan reload"
#		            return 4
#		        else
#		            return 1
#		        fi
#		    else
#		        return 0
#		    fi			
#		fi
    else   
        return 0
    fi
}
#--------MAIN -------------
if [ "$FIRST_INSTALL" == "FIRST_INSTALL" ]; then
    if [ -f /usr/local/mor/mor_mnp.conf ]; then
        serverid_on_mor_conf=`awk -F";" '{print $1}' /etc/asterisk/mor.conf | grep server_id | awk -F"=" '{print $2}'`
        serverid_on_mnp_conf=`awk -F";" '{print $1}' /usr/local/mor/mor_mnp.conf | grep server_id | awk -F"=" '{print $2}' | sed 's/ //g'`
        if [ "$serverid_on_mor_conf" != "$serverid_on_mnp_conf" ]; then
            rm -rf /usr/local/mor/mor_mnp.conf            
        fi
    fi
    mnp_cfg_exists
else
    asterisk_is_running
    if [ "$?" != "0" ]; then
        exit 0
    fi
    mnp_enabled
    if [ "$MNP_ENABLED" == "0" ]; then    # MNP DB exists. Doing the rest of work to enable/fix MNP
        if [ -f /usr/local/mor/mor_mnp.conf ]; then
            serverid_on_mor_conf=`awk -F";" '{print $1}' /etc/asterisk/mor.conf | grep server_id | awk -F"=" '{print $2}'`
            serverid_on_mnp_conf=`awk -F";" '{print $1}' /usr/local/mor/mor_mnp.conf | grep server_id | awk -F"=" '{print $2}' | sed 's/ //g'`
            if [ "$serverid_on_mor_conf" != "$serverid_on_mnp_conf" ]; then
                rm -rf /usr/local/mor/mor_mnp.conf            
            fi
        fi
        mnp_cfg_exists
        fix_mnp
            report "Configurations for MNP" "$?"
    fi
fi
