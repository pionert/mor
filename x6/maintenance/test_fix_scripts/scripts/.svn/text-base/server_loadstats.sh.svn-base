#! /bin/sh

# Author:   Mindaugas Mardosas, Nerijus Sapola
# Company:  Kolmisoft
# Year:     2014
# About:	This script ensures that server load stats is running on server. This script must be running on every MOR server even if it is just DB server.

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

#------VARIABLES-------------
#----- FUNCTIONS ------------
#--------MAIN -------------

read_mor_db_settings
read_mor_gui_settings

if [ "$GUI_PRESENT" == "0" ] && [ "$DB_PRESENT" == "0" ]; then
    report "No need to run mor_server_loadstats here" 0
    exit 0
fi

mor_db_version_mapper

if [ "$MOR_MAPPED_DB_VERSION" -ge "140" ]; then
	if [ ! -f "/etc/init.d/mor_server_loadstats" ]; then 
		report "/etc/init.d/mor_server_loadstats is not present - server load stats is not installed" 1
		exit 1
	fi

	chkconfig --level 2345 mor_server_loadstats on	&>/dev/null
	if [ "$?" != "0" ]; then
		report "Failed to set runlevels for /etc/init.d/mor_server_loadstats. Try this command manually: chkconfig --level 2345 mor_server_loadstats on" 1
	fi

	if [ `ps aux | grep mor_server_loadstats | grep -v grep | wc -l` != "1" ]; then
		/etc/init.d/mor_server_loadstats start
		if [ `ps aux | grep mor_server_loadstats | grep -v grep | wc -l` != "1" ]; then
			report "Failed to start mor_server_loadstats daemon. Try to reinstall it" 1
		else
			report "mor_server_loadstats daemon started" 4
		fi
	else
	    report "mor_server_loadstats daemon works ok" 0
	fi
fi