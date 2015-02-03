#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This script is for CDR log backup during DB upgrade with percona. Launching this script is only required if you are going to work with calls table

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh
. /usr/src/mor/test/framework/asterisk_specific_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------
if [ -f "/var/log/mor/mor_core_cdr_log.sql" ]; then
	report "CDR log: /var/log/mor/mor_core_cdr_log.sql is already present. Backup it or remove it before proceeding" 1
	exit 1
fi
 

# MOR core version check
check_if_asterisk_core_version_lower_than "13.0.210" "EXIT"	# Exits if failure
if [ "$MOR_CORE_BRANCH" == "14" ]; then
	check_if_asterisk_core_version_lower_than "14.0.41" "EXIT"	# Exits if failure	
fi
# All other future versions will support this...


asterisk_enable_cdr_log
default_interface_ip
if [ "$MOR_LOG_CDR" == "on" ]; then
	report "CDR logging is enabled on this Asterisk server: $DEFAULT_IP. Press Enter to stop logging" 3
else
	report "Failed to enable CDR logging to /var/log/mor/mor_core_cdr_log.sql on server $DEFAULT_IP. Are you sure this server has Asterisk running" 1
	exit 1
fi

read  a # Waiting for enter press

asterisk_disable_cdr_log
if [ "$MOR_LOG_CDR" == "on" ]; then
	report "Failed to disable CDR logging" 3
	exit 1
else
	report "CDR logging successfully stopped. You can find your SQLs here: /var/log/mor/mor_core_cdr_log.sql" 3
fi