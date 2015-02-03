#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This function library is intended to speed up work with Asterisk

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------


#===== MOR CDR LOG SQLS ===
asterisk_cdr_log_status()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	# About:	This function disables CDR logging in full SQL format
 	#
 	# Returns:
 	#	MOR_LOG_CDR {on, off}
 
	MOR_LOG_CDR=`asterisk -rx "mor log cdr status" |awk -F"'" '{print $2}'`

}
asterisk_enable_cdr_log()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	# About:	This function enables CDR logging in full SQL format in case of disaster they could be easily used to import the changes to backuped database
 	#
 	# Returns:
 	#	MOR_LOG_CDR {on, off}

 	asterisk -rx "mor log cdr on" | grep "CDR logging is set to 'on'"
	asterisk_cdr_log_status
}


asterisk_disable_cdr_log()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	# About:	This function disables CDR logging in full SQL format
 	#
 	# Returns:
 	#	MOR_LOG_CDR {on, off}
 	
	asterisk -rx "mor log cdr off" | grep "CDR logging is set to 'off'" 
	asterisk_cdr_log_status
}

#---------

check_if_asterisk_core_version_lower_than()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	# About:	This function checks if Asterisk core version is lower than defined in parameter
	#
	# Parameters
	#	$1	-	core version to compare with
	#	$2  -	optional parameter "EXIT". If provided - will cause script to exit if core version is lower than provided in $1 parameter
 	#
 	# Returns
 	#	RESULT { 0 - versions are equal, 1 - current installed core version is bigger. 2 core version provided in parameter is bigger (system has lower version) }
	
	CORE_VERSION_TO_COMPARE_WITH="$1"
	EXIT_IF_FAILURE="$2"

	asterisk_is_running
	if [ "$?" != "0" ]; then
		report "Asterisk is not running" 1
		if [ "$EXIT_IF_FAILURE" == "EXIT" ]; then
			exit 1
		fi
	fi

	mor_core_version

	vercomp "$MOR_CORE_VERSION" "$CORE_VERSION_TO_COMPARE_WITH"
	RESULT="$?"
	
	if [ "$EXIT_IF_FAILURE" == "EXIT" ] && [ "$RESULT" == "2" ]; then
		report "System has lower MOR core version: $MOR_CORE_VERSION than required: $CORE_VERSION_TO_COMPARE_WITH" 1
		exit 2
	fi

	return $RESULT
}
