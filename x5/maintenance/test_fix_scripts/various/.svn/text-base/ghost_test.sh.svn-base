#! /bin/sh

# Author:   Nerijus
# Company:  Kolmisoft
# Year:     2015
# About:    Checks if server is vulnerable by ghost bug in glibc (CVE-2015-0235)

. /usr/src/mor/x5/framework/bash_functions.sh

os_processor_type
if [ "$?" == "1" ]; then
    result=`/usr/src/mor/x5/maintenance/ghost_test/ghosttest_64`
elif [ "$?" == "0" ]; then
    result=`/usr/src/mor/x5/maintenance/ghost_test/ghosttest_32`
else
    report "Failed to check vulnerability by ghost bug in glibc" 1
    exit 1
fi

if [ "$result" == "secure" ]; then
    report "server is not vulnerable by ghost bug in glibc" 0
    exit 0
elif [ "$result" == "vulnerable" ]; then
    report "server is vulnerable by ghost bug. Please do yum update glibc and reboot server" 1
    exit 0
else
    report "Failed to check vulnerability by ghost bug in glibc" 1
    exit 1
fi