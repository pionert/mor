#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This script reacts to events passed from zabbix system and launches script which starts Master or Slave server for SIP proxy on datacentres which do not support HeartBeat
#
# Example: /path/to/script/ha.sh /usr/local/mor/ha.conf /var/log/ha.log 127.0.0.1 PROBLEM
#

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

SERVERS_CONFIGURATION="$1"
LOG_FILE="$2"
ZABBIX_GIVEN_IP="$3"
ZABBIX_GIVEN_STATUS="$4"

HA_LOG="$LOG_FILE"

#----- FUNCTIONS ------------

event_logger()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	# About:	This function checks if script is Master
	#
	# Parameters:
	#	$1	-	Message to log

	message="$1"

	echo "`date` $message" >> $HA_LOG
}


check_if_server_exists_in_configuration()
{
	# Returns:
	#	0	-	not found
	#	1	-	found

	local IP_TO_CHECK="$1"

	FOUND=`grep "$IP_TO_CHECK" $SERVERS_CONFIGURATION | wc -l`
	if [ "$FOUND" == "0" ]; then
		event_logger "Server not found in configuration: IP: $ZABBIX_GIVEN_IP, STATUS: $ZABBIX_GIVEN_STATUS"
		exit 1
	fi
}

get_information_from_configuration()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	# About:	This function prepares variables according to configuration
	#
	# Configuraton file format:
	#	MASTER_IP;START_MASTER_SCRIPT_PATH;START_SLAVE_SCRIPT_PATH
	#
	# Parameters:
	#	$1	-	IP 
	#
	local IP_TO_CHECK="$1"

	DEBUG="TRUE"

	CFG_STRING=`grep $IP_TO_CHECK $SERVERS_CONFIGURATION | head -n 1`
	MASTER_IP=`echo $CFG_STRING | awk -F";" '{print $1}'`
	START_MASTER_SCRIPT_PATH=`echo $CFG_STRING | awk -F";" '{print $2}'`
	START_SLAVE_SCRIPT_PATH=`echo $CFG_STRING | awk -F";" '{print $3}'`


	if [ "$DEBUG" == "TRUE" ]; then
		echo "$MASTER_IP"
		echo "$START_MASTER_SCRIPT_PATH"
		echo "$START_MASTER_SCRIPT_PATH"
	fi


	if [ ! -f "$START_MASTER_SCRIPT_PATH" ]; then
		event_logger "START_MASTER_SCRIPT_PATH: $START_MASTER_SCRIPT_PATH does not exist"
		exit 1
	fi

	if [ ! -f "$START_SLAVE_SCRIPT_PATH" ]; then
		event_logger "START_SLAVE_SCRIPT_PATH: $START_SLAVE_SCRIPT_PATH does not exist"
		exit 1
	fi
}
#--------MAIN -------------

if [ ! -f "$SERVERS_CONFIGURATION" ]; then
	event_logger "Configuration file $SERVERS_CONFIGURATION does not exist"
	exit 1
fi

event_logger "Got new event from zabbix: IP: $ZABBIX_GIVEN_IP, STATUS: $ZABBIX_GIVEN_STATUS"
check_if_server_exists_in_configuration "$ZABBIX_GIVEN_IP"

get_information_from_configuration "$ZABBIX_GIVEN_IP"

if [ "$ZABBIX_GIVEN_STATUS" == "PROBLEM" ]; then
	$START_SLAVE_SCRIPT_PATH	# Moving floating IP to Slave
	event_logger "Moving floating IP to slave. Status from Slave start script: $?"
elif [ "$ZABBIX_GIVEN_STATUS" == "OK" ]; then
	$START_MASTER_SCRIPT_PATH	# Moving floating IP back to Master
	event_logger "Moving floating IP to Master. Status from Master start script: $?"
fi