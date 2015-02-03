#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	Check if raid check cron exists. This causes problems described here: #8646

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

if [ -f "/etc/cron.d/raid-check" ] && [ `df -P | grep "/$" | awk '{print $2}' | head -n 1` -ge "419430400" ]; then	# If system has bigger than 400 GB hard disk
	report "Found cron: /etc/cron.d/raid-check , RAID check cron can cause serious availability issues on big hard disks" 2
	#cat /etc/cron.d/raid-check
	#df -h
else
    report "raid-check cron not present, good" 0
fi
