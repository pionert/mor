#! /bin/sh

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2013
# About:    Script checks if S3 backup system is intalled on server hosted by OVH.

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

uname -n | grep ovh &> /dev/null
if [ "$?" == "0" ]; then
    if [ ! -f "/root/.s3cfg" ]; then 
        report "Server is hosted by OVH, but S3 backup system is not installed. Check if this server should have S3 backups enabled" 1
        exit 1;
    else
        report "Server is hosted by OVH, and S3 backup system is installed." 0
        exit 0;
    fi
else
    report "Server is hosted not by OVH, no need to check if S3 backup system is installed." 0
    exit 0;
fi