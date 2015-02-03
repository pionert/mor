#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks if DNS works

. /usr/src/mor/x5/framework/bash_functions.sh

#------VARIABLES-------------
SVN_KOLMISOFT_COM_ADDRESS="46.251.50.103"

#----- FUNCTIONS ------------

check_dns()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks if the server can correctly resolve kolmisoft.com svn address

    # Returns:
    #   0   -   DNS settings OK
    #   1   -   DNS settings are wrong

    local ADDRESS=`/usr/bin/resolveip svn.kolmisoft.com 2> /dev/null | awk '{print $NF}'`;

    if [ "$SVN_KOLMISOFT_COM_ADDRESS" == "$ADDRESS" ]; then
        return 0
    else
        # ip does not match, maybe we are in the Kolmisoft local network?
        ping -c 1 svn.kolmisoft.com &> /dev/null
        if [ "$?" == "0" ]; then
            return 0;
        else
            return 1;
        fi
    fi
}

fix_dns()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks adds public dns servers if the script detects that current settings are malfunctioning
    #
    # Returns:
    #   0   -   DNS settings were fixed
    #   1   -   Failed to fix DNS settings

    _mor_time;
    mkdir -p /usr/local/mor/backups/etc
    cp /etc/resolv.conf /usr/local/mor/backups/etc/resolv.conf_$mor_time
    echo -e "nameserver 4.2.2.2\nnameserver 8.8.8.8\nsearch localdomain" > /etc/resolv.conf
    check_dns
    if [ "$?" == "0" ]; then
        return 0
    else
        return 1
    fi
}
#---------------------------

check_dns
if [ "$?" == "0" ]; then
    report "DNS settings: /usr/bin/resolveip svn.kolmisoft.com" 0
else
    fix_dns
    if [ "$?" == "0" ]; then
        report "DNS settings: /usr/bin/resolveip svn.kolmisoft.com" 4
    else
        report "Failed to fix DNS settings" 1
    fi
fi
