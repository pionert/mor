#! /bin/sh
# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    This script downloads a know list of IP's scanning VoIP networks for vulnerabilities
#
# Important information:
#    /usr/local/mor/ip_whitelist  - list here IP addresses you do not wish to be banned like this:
#        127.0.0.1
#        192.168.0.1
#        and so on...
#
#    Log files:
#        /var/log/mor/mor_global_grid_defense.log

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------
FIRST_PARAM="$1"
OFFENDER_LIST="http://fail2ban.kolmisoft.com/offenders"
ONE_OR_MORE_IP_ADDRESSES_WERE_BANNED="FALSE"

#----- FUNCTIONS ------------

install_upgrade_global_grid_defense_if_not_installed()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2013
    # About:    This function installs global grid defense system in server
    #

    report "Installing/Upgrading global grid defense" 3
    cp -fr /usr/src/mor/sh_scripts/global_grid_defense.sh /usr/local/mor/global_grid_defense.sh
    chmod 744 /usr/local/mor/global_grid_defense.sh
    
    echo "* */3 * * *  root /bin/bash  -l  /usr/local/mor/global_grid_defense.sh" > /etc/cron.d/global_grid_defense
    chmod 644 /etc/cron.d/global_grid_defense
    
    if [ ! -f "/usr/local/mor/ip_whitelist" ]; then # Adding Kolmisoft office IP's, feel free to add here your own IP's
        echo -e "127.0.0.1\n46.251.50.103\n86.38.9.136\n78.56.240.119" > /usr/local/mor/ip_whitelist
    fi

    if [ -f "/usr/local/mor/global_grid_defense.sh" ] && [ -f "/etc/cron.d/global_grid_defense" ]; then
        report "Global grid defense" 0
    fi
}

check_if_IP_is_banned()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2013
    # About:    This function checks if IP address is already banned by Fail2Ban or not.
    #
    # Returns:
    #    0    -    Address is not banned
    #    1    -    Address is banned
    #    
    #    Global variable:
    #        BANNED - {"TRUE", "FALSE"}

    IP_ADDRESS_TO_CHECK="$1"
    
    if [ ! -f "/dev/shm/.iptables_output" ]; then
        report "Failed to generated iptables rules " 1
        exit 1
    fi
        
    if [ `grep -F "DROP" /dev/shm/.iptables_output | grep $IP_ADDRESS_TO_CHECK | wc -l` != "0" ]; then
        BANNED="TRUE"
        return 1 # banned
    else
        BANNED="FALSE"
        return 0 # banned
    fi
}

ban_ip()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2013
    # About:    This function handles IP addresses blocking and logging

    ADDRESS_TO_BAN="$1"
    iptables -A INPUT -s "$ADDRESS_TO_BAN" -j DROP
    if [ "$?" == "0" ]; then
        ONE_OR_MORE_IP_ADDRESSES_WERE_BANNED="TRUE"
        touch /var/log/mor/mor_global_grid_defense.log # Ensuring that log file exists
        echo "Blocked IP: $ADDRESS_TO_BAN" >> /var/log/mor/mor_global_grid_defense.log
    else
        echo "Failed to ban IP $ADDRESS_TO_BAN using command: iptables -A INPUT -s $ADDRESS_TO_BAN -j DROP"
    fi
}
check_if_IP_address_is_in_whitelist()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2013
    # About:    This function checks if IP address is in whitelists.
    #
    # Returns:
    #    0    -    IP is not in IP whitelist
    #    1    -    IP is in IP whitelist
    #
    # Returns global variable:
    #    IP_IS_WHITELISTED={"TRUE", "FALSE"}
    #

    IP_ADDRESS_TO_CHECK="$1"

    if [ ! -f "/usr/local/mor/ip_whitelist" ]; then
        IP_IS_WHITELISTED="FALSE"
        return 0
    fi

    if [ `grep $IP_ADDRESS_TO_CHECK  /usr/local/mor/ip_whitelist | wc -l` == "0" ]; then
        IP_IS_WHITELISTED="FALSE"
        return 0
    else
        IP_IS_WHITELISTED="TRUE"
        return 1        
    fi
}

#--------MAIN -------------


if [ "$FIRST_PARAM" == "INSTALL" ]; then
    install_upgrade_global_grid_defense_if_not_installed
else
    report "Downloadig IP list" 3
    
    curl $OFFENDER_LIST | sed '/^$/d' > /dev/shm/.IP_ADDRESSES_TO_BAN    # Getting the list of IP adresses to ban

    if [ -f "/dev/shm/.IP_ADDRESSES_TO_BAN" ]; then
        report "Generating currently blocked addresses list" > 3

        if [ ! -f "/etc/sysconfig/iptables" ]; then
            /etc/init.d/iptables save
        fi
        
        cp -fr /etc/sysconfig/iptables /dev/shm/.iptables_output
    
        FILE="/dev/shm/.IP_ADDRESSES_TO_BAN"
        exec < $FILE
        while read IP_TO_BAN
        do
            
            validateIP "$IP_TO_BAN"
            if [  "$IP_IS_VALID" == "FALSE" ]; then
                mor_resolve_ip "$IP_TO_BAN"

                if [ "$RESOLVED_IP" == "FALSE" ]; then
                    continue
                else
                    IP_TO_BAN="$RESOLVED_IP"
                fi
            fi
        
            #------ Checking if we have to block this IP ----
            check_if_IP_address_is_in_whitelist  "$IP_TO_BAN"
            if [ "$IP_IS_WHITELISTED" == "TRUE" ]; then
                echo "Not blocking $IP_TO_BAN - it is in whitelist"
                continue # continue with next IP, this one is whitelisted and is ment to be never blocked
            fi

            check_if_IP_is_banned "$IP_TO_BAN"
            if [ "$BANNED" == "TRUE" ]; then
                continue # continue with next IP, this one is already banned
            fi

            ban_ip "$IP_TO_BAN" #---- BAN IP if we got here
        done

        if [ "$ONE_OR_MORE_IP_ADDRESSES_WERE_BANNED" == "TRUE" ]; then
            /etc/init.d/iptables save # Saving iptables rules in order they would be available after reboot
            echo "Saving iptables rules" >> /var/log/mor/mor_global_grid_defense.log
        else
            echo "No new IP's to block."
        fi
        # Cleanup
        #rm -rf /dev/shm/.iptables_output /dev/shm/.IP_ADDRESSES_TO_BAN 
    else
        report "Failed to download IP addresses to block list." 1
    fi
fi


