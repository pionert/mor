#! /bin/sh
#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  This script tests if /etc/asterisk/h323.conf:
#       1. has uncommented line: bindaddr = x.x.x.x, if not - produces a notice

. /usr/src/mor/x6/framework/bash_functions.sh

#-------------Functions---------------
bindaddr()
{
    #   Author: Nerijus Sapola
    #   Year:   2014
    #   About:  This function tests if /etc/asterisk/h323.conf has config bindaddr UNCOMMENTED. If not - produces a notice



    check_if_setting_match /etc/asterisk/h323.conf "bindaddr" "bindaddr"    #this time on
    if [ "$?" == "2" ]; then
        #separator "/etc/asterisk/h323.conf" #until there will be more test this one is placed here
        report "bindaddr is commented in /etc/asterisk/h323.conf" 3
    else
        h323_bindaddr=`grep bindaddr /etc/asterisk/h323.conf | awk -F"=" '{print $2}' | awk -F";" '{ print $1 }' | awk '{$1=$1}1'`
        ip a | grep $h323_bindaddr &>/dev/null
        if [ "$?" == "0" ]; then
            #h323 bindaddr is found on servers ip's list; all is good
            exit 0
        elif [ -f /etc/ha.d/haresources ]; then
            grep $h323_bindaddr /etc/ha.d/haresources &>/dev/null
            if [ "$?" == "0" ]; then
                #h323 bindaddr matches virtual IP; all is good
                exit 0
            else
                report "bindaddr is incorrect in /etc/asterisk/h323.conf" 1
            fi
        else
            report "bindaddr is incorrect in /etc/asterisk/h323.conf" 1
        fi
    fi
}
#================= MAIN ====================
asterisk_is_running
STATUS="$?"
if [ "$STATUS" != "0" ]; then
    exit 0
fi



bindaddr
