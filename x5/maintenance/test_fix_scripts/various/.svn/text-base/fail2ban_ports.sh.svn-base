#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    This script checks various services ports and Fail2Ban configuration

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

#------VARIABLES-------------
#----- FUNCTIONS ------------
#--------MAIN -------------
sshd_port()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function checks and returns sshd port set in /etc/ssh/sshd_config
    
    PORT_FOUND=`awk -F'#' '{print $1}' /etc/ssh/sshd_config | grep Port | head -n 1 | awk '{print $2}'`
    
    if [ "$PORT_FOUND" == "" ]; then
        SSH_PORT=22
        return 22
    else
        SSH_PORT=$PORT_FOUND
        return $PORT_FOUND
    fi
}

fail2ban_check_fix_ssh_port()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This script checks sshd port set in /etc/sshd/config and the one set in jail.conf
    
    sshd_port
    if [ `grep 'port=ssh' /etc/fail2ban/jail.conf | wc -l` -ge "1" ] && [ "$SSH_PORT" != "22" ]; then
        #If port is not set to default and jail.conf is configured for default
        sed -i "s%port=ssh%port=$SSH_PORT%g" /etc/fail2ban/jail.conf
        report "Mapped correctly port for SSH: /etc/fail2ban/jail.conf set port=$SSH_PORT" 3
        if [ `grep "port=$SSH_PORT" /etc/fail2ban/jail.conf | wc -l` == "0" ]; then
            report "Something went wrong with Fail2Ban SSH setup! Go to /etc/fail2ban/jail.conf config and set port=$SSH_PORT for SSH sections" 1
            exit 1
        else
            service fail2ban restart
        fi
    else
	report "Fail2Ban check SSH port 22 is ok" 0
    fi
}

#====== Main ======

fail2ban_check_fix_ssh_port
 