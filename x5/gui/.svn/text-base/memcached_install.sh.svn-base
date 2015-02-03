#!/bin/bash

. /usr/src/mor/x5/framework/bash_functions.sh

if [ -f /etc/init.d/memcached ]; then
    report "Memcached already installed" 0
else
    yum -y install memcached
    chkconfig --levels 2345 memcached on
    /etc/init.d/memcached restart

    if [ -f /etc/init.d/memcached ]; then
	report "Memcached installed" 4
    else
	report "Failed to install memcached. Try to do it manually" 1
    fi
fi

grep "127.0.0.1" /etc/sysconfig/memcached &>/dev/null
if [ "$?" == "1" ]; then
    report "Changing memcached bindaddr to 127.0.0.1" 3
    sed -i 's/OPTIONS=""/OPTIONS="-l 127.0.0.1"/g' /etc/sysconfig/memcached
    /etc/init.d/memcached restart
    
    #check if file was actually changed
    grep "127.0.0.1" /etc/sysconfig/memcached &>/dev/null
    if [ "$?" == "0" ]; then
       report "Memcached bindaddr changed to 127.0.0.1" 0
    else
       report "Memcached bindaddr was NOT changed to 127.0.0.1. Please check file /etc/init.d/memcached manually. OPTIONS line should look like this:" 2
       report "OPTIONS=\"-l 127.0.0.1\"" 2
    fi
fi
