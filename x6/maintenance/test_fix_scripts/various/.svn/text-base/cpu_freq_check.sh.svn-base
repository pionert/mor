#! /bin/sh

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2014
# About:    Script checks if CPU is not stuck on its lowest frequency mode. It is common issue with Hetzner servers.

. /usr/src/mor/x6/framework/bash_functions.sh

CPU_FREQ=`grep "cpu MHz" /proc/cpuinfo | head -n 1 | awk '{print $4}' | awk -F"." '{print $1}'`
if [ "$CPU_FREQ" -lt "2000" ]; then
    report "CPU is running at $CPU_FREQ MHz" 2
fi
