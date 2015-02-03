#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    This script checks if S3 backups are working correctly
#
# Returns:
#   0   -   on success
#   1   -   on failure

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------
PATH_TO_S3_configuration="$1"
PERIOD="$2" # {day, week, month}

if [ ! -f "$PATH_TO_S3_configuration" ]; then
    if [ "$REPORT_TO_SCREEN" == "TRUE" ]; then
        echo 0
    fi
    exit 1    
fi

USER_ID=`grep USER_PATH $PATH_TO_S3_configuration | awk '{print $3}'`
S3BUCKET="kolmibackups"

if [ ! -f /usr/bin/bc ]; then
    yum -y install bc
fi


#----- FUNCTIONS ------------
check_if_s3_backup_exists()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function checks if backup was created for specified period.
    #   $1 - PERIOD: {day, week, month}
    #   $2 - USER_ID
    #
    #   Returns:
    #       0   -   backup OK
    #       1   -   backup FAILED
    
    local S3BUCKET="$1"
    local S3PATH="$2"
    local PERIOD="$3"
    
    S3cmd=`s3cmd --config="$PATH_TO_S3_configuration" ls s3://${S3BUCKET}/${S3PATH}${PERIOD}/`
    if [ "$?" != "0" ]; then
        echo 0
        exit 1
    fi
    
    LAST_BACKUP=`echo $S3cmd | sort | tail -n 1 | awk '{print $NF }'`
    
    BACKUP_YEAR=`echo $LAST_BACKUP | awk -F"." '{print $2}'`
    BACKUP_MONTH=`echo $LAST_BACKUP | awk -F"." '{print $3}'`
    BACKUP_DAY=`echo $LAST_BACKUP | awk -F"." '{print $4}'`

    # 24 hours - 86400 seconds
    # 7 days - 604800
    
    CURRENT_TIME_STAMP=`date +%s`

    BACKUP_TIMESTAMP=`date -d "$BACKUP_YEAR/$BACKUP_MONTH/$BACKUP_DAY" "+%s"`
    if [ "$?" != "0" ]; then
        echo 0
        exit 1
    fi

    if [ "$PERIOD" == "day" ]; then
        COMPARE_WITH=`echo "$CURRENT_TIME_STAMP - 90000" | bc` # 9000s = 25 hours
    elif [ "$PERIOD" == "week" ]; then
        COMPARE_WITH=`echo "$CURRENT_TIME_STAMP - 691200" | bc` # 691200 = 8 days
    elif [ "$PERIOD" == "month" ]; then
        COMPARE_WITH=`echo "$CURRENT_TIME_STAMP - 2764800" | bc` # 2764800 = 32 days
    fi
    
    if [ "$BACKUP_TIMESTAMP" -lt "$COMPARE_WITH" ]; then
        return 1    # BAD! - backup failed. Backup we have is older
    fi   
    return 0 
}

#--------MAIN -------------

check_if_s3_backup_exists "$S3BUCKET" "$USER_ID" "day"
if [ "$?" == "0" ]; then
    echo "1" # For zabbix - 1 counts as OK
else
    echo "0" # For zabbix - 0 counts as Failed
fi

