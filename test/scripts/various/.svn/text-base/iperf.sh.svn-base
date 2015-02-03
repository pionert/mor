#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script installs a tool required for netwrok performance testing.
#           http://openmaniak.com/iperf.php

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
#--------MAIN -------------
if [ ! -f /usr/bin/iperf ]; then
    cd /usr/src
    

    os_processor_type
    if [ "$_64BIT" == "1" ]; then
        wget -T 20 -c http://www.kolmisoft.com/packets/iperf-2.0.5-1.el5.x86_64.rpm &> /dev/null
    else
        wget -T 20 -c http://www.kolmisoft.com/packets/iperf-2.0.5-1.el5.i386.rpm &> /dev/null
    fi

    yum -y --nogpgcheck install iperf-2.0.5-1.el5.*.rpm
    if [ -f /usr/bin/iperf ]; then
        report "iperf tool was installed" 4
    else
        report "iperf tool install failed, check if http://www.kolmisoft.com/packets/iperf-2.0.5-1.el5.i386.rpm is accessible from the server" 1
    fi
fi
