#! /bin/sh
# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2010
# About:    This script checks full duplex status

. /usr/src/mor/x6/framework/bash_functions.sh

DEBUG=0

#===================FULL DUPLEX CHECK=======================================
ethtool_check_eth()
{
    local device="$1"
	#argument 1 - device. example: eth0
    if [ ! -f "/sbin/ethtool" ] ||  [ ! -f "/usr/sbin/ethtool" ]; then
        yum -y install ethtool
    fi
    
     DUPLEX=`ethtool $device 2> /dev/null | grep Duplex | awk '{print $2}'`

     if [ "$DUPLEX" == "Full" ]; then
        if [ "$DEBUG" == "1" ]; then echo "$DUPLEX"; fi
        return 0;
    
     elif [ -z "$DUPLEX" ]; then
        report "Cannot read DUPLEX status on $device" 3
        return 0;
     else
        if [ "$DEBUG" == "1" ]; then echo "$DUPLEX"; fi
          
        local ROWS=`ethtool $device | sed '/^$/d' | wc -l`
        if [ "$ROWS" != "3" ]; then
            echo "Information detected about your network card: $device:"
            ethtool $device 2> /dev/null  
            return 1;
        fi
        return 0
     fi
}
#=============================================================================

detect_vm
if [ "$?" != "0" ]; then        # if it is not a virtual machine
    /sbin/ifconfig | grep eth | awk '{ print $1}' | while read network_card; do
        ethtool_check_eth $network_card
        STATUS="$?"
        report "Full DUPLEX on network card: $network_card" "$STATUS"
        if [ "$STATUS" != "0" ]; then
            exit 1
        fi
    done
else
    report "VM detected, network full duplex test skipped" 3
fi


