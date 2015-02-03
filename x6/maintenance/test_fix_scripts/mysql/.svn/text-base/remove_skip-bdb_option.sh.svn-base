#! /bin/sh

# Author:   Mindaugas Mardosas, Nerijus Sapola
# Company:  Kolmisoft
# Year:     2012
# About:    This script is required to fix mysql configuration provided by MOR when we have MySQL 5.1=<  version. Without this fix MySQL will not start

. /usr/src/mor/x6/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

mysql_version()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function determins mysql version and a branch
   
    MYSQL_VERSION=`mysql --version | grep -o "Distrib [0-9.]*" | awk '{print $2}'`
    MYSQL_VERSION_BRANCH=`echo $MYSQL_VERSION | awk -F"." '{print $1}'`
}
mysql_version


check_if_skip_bdb_option_is_present()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function check if  skip-bdb mysql option exists. If it exists and mysql version is higher than 5.0.x - mysql refuses to start
    # Returns:
    #   0   -   OK, option not found
    #   1   -   Failed, option was found

    grep skip-bdb /etc/my.cnf &> /dev/null
    if [ "$?" == "1" ]; then
        return 0
    else
        return 1
    fi  
}

remove_skip_bdb_option_from_mysql_config()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function removes skip-bdb mysql option if needed

    mkdir -p /usr/local/mor/backups/my_cnf/
    _mor_time
    cp /etc/my.cnf /usr/local/mor/backups/my_cnf/my.cnf_$mor_time
    local tmpfile=`mktemp`
    sed '/skip-bdb/d' /etc/my.cnf > $tmpfile
    mv $tmpfile /etc/my.cnf

}
#--------MAIN -------------

check_if_skip_bdb_option_is_present
if [ "$?" == "1" ]; then
    mysql_version
    ruby /usr/src/mor/x6/framework/which_version_is_bigger.rb $MYSQL_VERSION "5.0.9"
    if [ "$?" == "1" ]; then
        remove_skip_bdb_option_from_mysql_config        
        check_if_skip_bdb_option_is_present
        if [ "$?" == "0" ]; then
            report "MySQL skip-bdb option removed from /etc/my.cnf" 4
            report "Please restart MySQL" 3
        else
            report "Failed to remove a skip-bdb option from /etc/my.cnf" 1
        fi
    fi
else
    report "skip-bdb not present in my.cnf" 0
fi



