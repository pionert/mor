#! /bin/sh

# Author:   Mindaugas Mardosas, Nerijus Sapola
# Company:  Kolmisoft
# Year:     2011, 2012
# About:    This script checks if Asterisk is under NAT and informs if some settings are wrong when Asterisk is under NAT

. /usr/src/mor/x6/framework/bash_functions.sh


export PATH="/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
export LANG="en_US.UTF-8"

#------VARIABLES-------------

#----- FUNCTIONS ------------
check_sip_conf_for_nat_settings()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks current NAT settings in sip.conf


    local externip=`awk -F";" '{ print $1}' /etc/asterisk/sip.conf | grep externip | wc -l`
    local externhost=`awk -F";" '{ print $1}' /etc/asterisk/sip.conf | grep externhost | wc -l`
    if [ "$externip" == "0" ] && [ "$externhost" == "0" ]; then
        report "NAT detected and you have not set externip neither externhost in /etc/asterisk/sip.conf" 6
    fi

    local localnet=`awk -F";" '{ print $1}' /etc/asterisk/sip.conf | grep localnet | wc -l`
    if [ "$localnet" == "0" ]; then
        report "NAT detected and you have not set localnet in /etc/asterisk/sip.conf" 6
    fi

}

get_all_interfaces_ip()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function gets all available hosts IP's assigned to host eth* interfaces

    all_ip=( `ifconfig | grep "inet addr:" | awk '{print $2}' | awk -F ':' '{print $2}' | grep -v "^127"` )
}

check_if_ip_belongs_to_private_range()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This script checks if a given IP belongs to a private IP range. Function does not check if IP is in valid format x.x.x.x, it is your responsibility to ensure that
    #
    # Arguments:
    #  $1   -   IP to check
    #
    # Returns:
    #   0   -   IP belongs to a private range.
    #   1   -   IP DOES NOT belong to a private IP range.

    IP_IN_PRIV_RANGE=`echo "$1" | grep -v "^10\.\|^192\.168\|^172\.16\|^172\.17\|^172\.18\|^172\.19\|^172\.20\|^172\.21\|^172\.22\|^172\.23\|^172\.24\|^172\.25\|^172\.26\|^172\.27\|^172\.28\|^172\.29\|^172\.30\|^172\.31" | wc -l`
    return $IP_IN_PRIV_RANGE
}
check_if_system_is_under_nat()
{
    # Author: Mindaugas Mardosas
    # Year:   2011
    # About:  This function checks if at least one IP assigned to eth* interface belongs to private IP range
    #
    # Returns:
    #   0   -  server is under NAT
    #   1   -  server is not under NAT

    #this is important only for Asterisk, so we will check if asterisk is running
    get_all_interfaces_ip
    for element in $(seq 0 $((${#all_ip[@]} - 1)))  #will go throw the config and check against every setting mentioned in variable all_ip
    do
        check_if_ip_belongs_to_private_range "${all_ip[$element]}"
        if [ "$?" == "0" ]; then #ip belongs to private range
            return 0;
        else
            return 1;
        fi
    done
}
#--------MAIN -------------

asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0
fi

check_if_system_is_under_nat
if [ "$?" == "1" ]; then
    report "NAT not detected" 0
else    #NAT was detected
    check_sip_conf_for_nat_settings
fi
