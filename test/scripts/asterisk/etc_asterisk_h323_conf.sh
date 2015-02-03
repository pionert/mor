#! /bin/sh
#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  This script tests if /etc/asterisk/h323.conf:
#       1. has uncommented line: bindaddr = x.x.x.x, if not - produces a notice

. /usr/src/mor/test/framework/bash_functions.sh

#-------------Functions---------------
bindaddr()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2010
    #   About:  This function tests if /etc/asterisk/h323.conf has config bindaddr UNCOMMENTED. If not - produces a notice



    check_if_setting_match /etc/asterisk/h323.conf "bindaddr" "bindaddr"    #this time on
    if [ "$?" == "2" ]; then
        separator "/etc/asterisk/h323.conf" #until there will be more test this one is placed here
        report "bindaddr is commented in /etc/asterisk/h323.conf" 3
    fi
}
#================= MAIN ====================
asterisk_is_running
STATUS="$?"
if [ "$STATUS" != "0" ]; then
    exit 0
fi



bindaddr
