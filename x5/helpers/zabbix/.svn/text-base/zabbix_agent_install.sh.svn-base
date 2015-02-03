#! /bin/sh

#   Author:   Mindaugas Mardosas
#   Company:  Kolmisoft
#   Year:     2011
#   About:    This script installs a zabbix agent.
#   
#   Please note, that you have to register zabbix monitored server in zabbix itself and assign a required template

. /usr/src/mor/x5/framework/bash_functions.sh

#------VARIABLES-------------
ZABIX_SERVER_ADDRESS="176.31.122.225";        #later change this to zabbix.kolmisoft.com

_centos_version
if [ "$centos_version" == "5" ]; then
    PATH_TO_EPEL_REPO_PACKET="http://dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm";
else    # centos 6
    PATH_TO_EPEL_REPO_PACKET="http://epel.uni-oldenburg.de/6/i386/epel-release-6-5.noarch.rpm";
fi

#----- FUNCTIONS ------------


#--------MAIN -------------
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

install_zabbix_agent()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This script installs a zabbix agent
    #
    #   Return:
    #       0   -   OK
    #       1   -   Zabbix configuration files not found /etc/zabbix

    rpm --quiet -Uvh $PATH_TO_EPEL_REPO_PACKET &> /dev/null
    yum -y --enablerepo=epel-testing install zabbix-agent  &> /dev/null

    chkconfig --levels 2345 zabbix-agent on #setting to start up

    if  [ -f "/etc/zabbix/zabbix_agent.conf" ] || [ -f "/etc/zabbix/zabbix_agentd.conf" ]; then
        replace_line /etc/zabbix/zabbix_agent.conf "Server=" "Server=$ZABIX_SERVER_ADDRESS"
        replace_line /etc/zabbix/zabbix_agentd.conf "Server=" "Server=$ZABIX_SERVER_ADDRESS"
        /etc/init.d/zabbix-agent restart  &> /dev/null
    else
        return 1;
    fi
}

#================================== MAIN =======================================

check_if_zabbix_agent_installed_and_running
if [ "$?" == "0" ]; then
    report "Zabbix Agent is already present" 0
else
    report "Installing Zabbix Agent, please be patient.." 3
    install_zabbix_agent
    if [ "$?" != "0" ]; then 
        report "Failed to install Zabbix Agent - after installation configurations in /etc/zabbix are not present" 1
        exit 1
    fi

    check_if_zabbix_agent_installed_and_running
    STATUS="$?"
    if [ "$STATUS" == "0" ]; then
        report "Zabbix Agent was installed" 4
    else
        report "Zabbix Agent was installed" 1
    fi
fi

#===== Fixes ====

/usr/src/mor/x5/maintenance/test_fix_scripts/various/zabbix_installed.sh


