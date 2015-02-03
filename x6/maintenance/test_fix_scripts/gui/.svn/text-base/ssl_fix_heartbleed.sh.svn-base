#!/bin/bash

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2014
# About:    Script updates openssl package if it is affected by heartbleed bug.

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh


rpm -qi openssl | grep Version | grep "1.0.1" >/dev/null
if [ "$?" == "1" ]; then
    report "Nothing to do. Bug was introduced on 1.0.1 version" 0
    exit 0
fi

ssl_version=`rpm -qi openssl | grep Version | grep "1.0.1" | awk '{print $3}'`

if [ "$ssl_version" == "1.0.1" ] || [ "$ssl_version" == "1.0.1a" ] || [ "$ssl_version" == "1.0.1b" ] || [ "$ssl_version" == "1.0.1c" ] || [ "$ssl_version" == "1.0.1d" ]; then
    yum -y install openssl
    report "Openssl was updated" 3
    exit 0
fi

if [ "$ssl_version" == "1.0.1e" ]; then
    ssl_release_digits=`rpm -qi openssl | grep Release | awk '{print $3}' | sed "s/[^0-9]//g"`
    if [ "$ssl_release_digits" -lt "16657" ]; then
        yum -y install openssl
        report "Openssl was updated" 3
        exit 0
    fi
fi

report "SSL version is without Heartblead bug" 0