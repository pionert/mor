#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks if zabbix agent exists in the system - if yes - checks if it is running.  Zabbix is not intended to be installed on all systems by default, so script does not take any action to install it if it is not present

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
check_if_zabbix_agent_installed_and_running()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This script checks if zabbix agent is installed
    #
    #   Returns:
    #   0   -   OK
    #   1   -   FAILED, zabbix is not installed
    #   3   -   Zabbix is not running

    if [ ! -f "/etc/zabbix/zabbix_agent.conf" ] || [ ! -f "/etc/zabbix/zabbix_agentd.conf" ] || [ ! -f "/etc/init.d/zabbix-agent" ]; then
        return 1
    fi

    /etc/init.d/zabbix-agent status &> /dev/null
    if [ "$?" != "0" ]; then
        return 3
    fi
}

configure_visudo()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function: 1) checks if sudo is installed, if not installs. 2) disables tty requirement for sudo commands, assigns zabbix permissions to monitor services properly

    if [ ! -s /usr/bin/sudo ]; then
        yum -y install sudo
    fi

    mkdir -p /usr/local/mor/backups/etc/
    cp /etc/sudoers /usr/local/mor/backups/etc/
    local temp=`mktemp`    
    sed '/requiretty\|zabbix/d' /etc/sudoers  > $temp
    echo "zabbix ALL=(ALL) NOPASSWD: /etc/init.d/httpd restart,/sbin/service ntpd status,/usr/sbin/asterisk,/usr/bin/mysqladmin,/usr/src/mor/test/scripts/various/fail2ban_running.sh,/usr/src/mor/test/scripts/gui/gui_access_from_localhost.sh,/usr/src/mor/test/zabbix/s3_check.sh /root/.s3cfg day,/usr/src/mor/test/zabbix/s3_check.sh /root/.s3cfg month,/usr/src/mor/test/zabbix/s3_check.sh /root/.s3cfg week,/sbin/service opensips status,/sbin/service mysqld status" >> $temp
    mv $temp /etc/sudoers  
    chmod 0440 /etc/sudoers
}

configure_zabbix_agentd()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function: 1) checks if sudo is installed, if not installs. 2) disables tty requirement for sudo commands
    #

    # Returns:
    #   0   -   OK
    #   1   -   Failed to configure
    #   4   -   FIXED

    local temp=`mktemp` 
	sed '/EnableRemoteCommands\|Server=/d' /etc/zabbix/zabbix_agentd.conf > $temp
    mv $temp /etc/zabbix/zabbix_agentd.conf  
    chmod 0440 /etc/zabbix/zabbix_agentd.conf

    awk -F"#" '{print $1}' /etc/zabbix/zabbix_agentd.conf | sed "s/ //g" | grep "Include=/usr/src/mor/test/zabbix/mor" &> /dev/null
    if [ "$?" != "0" ]; then    
        echo "Include=/usr/src/mor/test/zabbix/mor" >> /etc/zabbix/zabbix_agentd.conf 
        /etc/init.d/zabbix-agent restart
        #----Checking again
		awk -F"#" '{print $1}' /etc/zabbix/zabbix_agentd.conf | sed "s/ //g" | grep "Include=/usr/src/mor/test/zabbix/mor" &> /dev/null
        if [ "$?" == "0" ]; then    
            return 4
        else
            return 1
        fi
    fi
}
#--------MAIN -------------

check_if_zabbix_agent_installed_and_running            
STATUS="$?"
if [ "$STATUS" == "0" ]; then
    #-------- Getting the IP
    gui_exists
      GUI_STATUS="$?"
    apache_is_running
      APACHE_STATUS="$?"
    if [ "$GUI_STATUS" == "0" ] &&  [ "$APACHE_STATUS" == "0" ]; then
        DEFAULT_IP=`grep Web_URL /home/mor/config/environment.rb | awk -F"/|\"" '{print $4}'`
        RESOLVED_IP=`resolveip $DEFAULT_IP 2> /dev/null | grep "IP address" | awk '{print $NF}'` &>/dev/null
        if [ "$RESOLVED_IP" != "" ] && [ "$RESOLVED_IP" != "127.0.0.1" ]; then
            DEFAULT_IP="$RESOLVED_IP"
        fi
    else
       default_interface_ip
    fi
    #------
    report "Zabbix agent is installed and running\t\t Go to this host in Zabbix: http://176.31.122.225/zabbix/search.php?search=$DEFAULT_IP" 3
elif [ "$STATUS" == "3" ]; then
    report "Zabbix agent is installed and NOT running" 1
elif [ "$STATUS" == "1" ]; then #zabbix is not installed
    uname -n | grep ovh &> /dev/null
    if [ "$?" == "0" ]; then
        report "Server is hosted by OVH, but ZABBIX is not installed." 1
    fi
    exit 1; #no point in ruuning other commands in this script
fi

#--------
configure_zabbix_agentd
    report "Zabbix configuration" "$?"
#--------------
configure_visudo


