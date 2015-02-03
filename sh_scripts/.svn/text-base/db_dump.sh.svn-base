#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This script dumps current MOR database to (by default) /home directory

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------
BACKUP_PATH="$1"
#----- FUNCTIONS ------------


#--------MAIN -------------

if [ ! -d "$BACKUP_PATH" ]; then
	BACKUP_PATH="/home"
fi

dump_mor_db "$BACKUP_PATH"