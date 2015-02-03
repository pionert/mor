#! /bin/sh

#   Author: Mindaugas Mardosas
#   Year:   2010
#   About:  It is vitally important that server time would be correct during server install/upgrade. This script synchronizes system clock with one of internet ntp time servers
#
#   Arguments:
#
#       $1  -   FIRST_INSTALL           #  if this argument is present the script immeadiately exits if any failure occours this way aborting further installation
#       NO ARGUMENTS                    #  will try to synchronize the time, will report { FAILED, OK } silently


FIRST_INSTALL="$1"

. /usr/src/mor/x6/framework/bash_functions.sh


report "Starting time sync" 3

if  [ ! -f /usr/sbin/ntpdate ]; then
    yum -y install ntp
fi

if [ -f /etc/ntp.conf ]; then
    grep "tinker panic" /etc/ntp.conf &>/dev/null
    if [ "$?" == "1" ]; then
        #this one will not allow ntpd to turn off even if time offset is very high. It will sync time anyway instead.
        sed -i '1s/^/tinker panic 0\n/' /etc/ntp.conf
    fi
fi

if  [ -f /usr/sbin/ntpdate ]; then

    /usr/sbin/ntpdate ntp.ubuntu.com &> /dev/null    #hiding any output
else
    report "Failed to install ntpdate command which synchronizes your clock with one of the internet time servers.  Check server internet connection or contact the Kolmisoft team." 1
    if [ "$FIRST_INSTALL" == "FIRST_INSTALL" ]; then echo -e "\nThis type of problem WILL LEAD to serious problems during installation, aborting installation.\n"; fi
    exit 1;
fi

# Check if ntpd starts after server is restarted
if [ `chkconfig --list | grep ntpd | grep on | wc -l` == "0" ]; then
    chkconfig --levels 2345 ntpd on
    service ntpd restart
    report "Added ntpd service to autostart: chkconfig --levels 2345 ntpd on" 3
    #rm -rf /etc/cron.d/ntpdate &> /dev/null# no longer needed. MK: why not needed? servers are nto restarted very often, and sync must be perfect at all times
fi


/etc/init.d/ntpd stop >> /dev/null
/usr/sbin/ntpdate ntp.ubuntu.com >& /dev/null
/usr/sbin/ntpdate pool.ntp.org >& /dev/null # just in case, some stratum crap sometimes does not work out
/etc/init.d/ntpd start >> /dev/null



if [ "$?" == "0" ]; then
    report "NTP: time synchronized successfully" 0
    exit 0
else    #if fails
    if [ -f  /etc/init.d/ntpd  ]; then  #maybe ntpd daemon is interfering with ntpdate?

        /etc/init.d/ntpd stop &> /dev/null    #hiding any output

        /usr/sbin/ntpdate ntp.ubuntu.com    &> /dev/null    #hiding any output
        STATUS="$?"

        /etc/init.d/ntpd start &> /dev/null    #hiding any output

        if [ "$STATUS" == "0" ]; then
            report "NTP: time synchronized successfully" 0
            exit 0
        else
            report "Failed to synchronize your clock with one of the internet time servers, this could lead to serious problems, aborting installation." 1
            if [ "$FIRST_INSTALL" == "FIRST_INSTALL" ]; then exit 1; fi
        fi
    else
        report "Failed to synchronize your clock with one of the internet time servers, this could lead to serious problems, aborting installation." 1
        if [ "$FIRST_INSTALL" == "FIRST_INSTALL" ]; then exit 1; fi
    fi
fi


