#! /bin/sh

# Author:   Mindaugas Mardosas, Gilbertas Matusevicius
# Company:  Kolmisoft
# Year:     2013, 2014
# About:	This script installs background tasks if they are needed. Uninstalls them if they are not needed.

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

# This script designed to be called from x4/fix.sh
# It may not work correctly if called directly 

#------VARIABLES-------------

#----- FUNCTIONS ------------
create_cron_job()
{
	# Author:   Mindaugas Mardosas
	# Company:  Kolmisoft
	# Year:     2013
	# About:	This function installs new crontab. It takes care about the right permissions
	#
	# Arguments:
	#	$1	-	Cronjob content
	#	$2 	-	Cronjob path
	#	
	# Example:
	#	create_cron_job "*/1 * * * * root /usr/local/mor/m2_background_tasks >> /var/log/mor/background_tasks.log" "/etc/cron.d/mor_background_tasks"

	cron_job_content="$1"
	cron_job_path="$2"

	if [ ! -f "$cron_job_path" ]; then
		echo "$cron_job_content" > "$cron_job_path"
		chmod 644 "$cron_job_path"
		report "Cron: $cron_job_path created" 4
	else
		report "Cron: $cron_job_path already exists" 3
	fi
}

remove_alerts_cron()
{

	if [ -f "/etc/cron.d/mor_alerts_cron" ]; then
		report "DB is not present on this server. Removing /etc/cron.d/mor_alerts_cron" 3
		rm -rf /etc/cron.d/mor_alerts_cron
	fi
}

stop_alerts_daemon()
{
    service mor_alerts stop
    chkconfig --level 2345 mor_alerts off
    report "Stopping mor_alerts service" 3

}

#--------MAIN -------------
mor_db_version_mapper 
if [ "$MOR_MAPPED_DB_VERSION" -ge "140" ]; then
	read_mor_db_settings
	read_mor_replication_settings

	if [ "$DB_PRESENT" == 1 ]; then

		if [ "$DB_MASTER_MASTER" == "yes" ] || [ "$REPLICATION_S" == "1" ] || [ "$REPLICATION_M" == "1" ]; then # if some kind of replication is present
			if [ -f "/etc/cron.d/mor_alerts_cron" ]; then
				report "Cron: /etc/cron.d/mor_alerts_cron exists" 0
			else
				report "Cron: /etc/cron.d/mor_alerts_cron does not exist. Install it if needed with this command: '*/1 * * * * root /usr/src/mor/sh_scripts/keep_alerts_alive.sh' > /etc/cron.d/mor_alerts_cron" 2
				report "If this server is part of solution with DB replication, cron should be installed only in one server with DB" 3
				stop_alerts_daemon
				
			fi
		else	# DB exists, replication is not present
			create_cron_job "*/1 * * * * root /usr/src/mor/sh_scripts/keep_alerts_alive.sh" "/etc/cron.d/mor_alerts_cron"
		fi
	else	# DB is not present
		remove_alerts_cron
		stop_alerts_daemon
	fi
fi
