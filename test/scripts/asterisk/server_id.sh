#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks and fixes server_id in /etc/asterisk/mor.conf and /var/lib/asterisk/agi-bin/mor.conf

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

clean_line()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function cleans the line from spaces, tabs and comments, both: ";" and "#"
    
    #   Arguments:
    #       $1  -   a line that has to be cleaned
    #
    #   Returns:
    #       A global variable   $CLEANED_OUTPUT which holds the cleaned line

    CLEANED_OUTPUT=`echo $1 | awk -F"#|;" '{ print $1}' | sed 's/ //g' |  sed 's/\t//g'`;
}

check_if_server_id_match()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks if /etc/asterisk/mor.conf and /var/lib/asterisk/agi-bin/mor.conf have the same server_id = X

    # Returns:
    #   0   -   OK, ids match
    #   1   -   Failed, ids do not match

    etc_asterisk_mor_conf_server_id=`awk -F"#|;" '{ print $1}' /etc/asterisk/mor.conf | sed 's/ //g' |  sed 's/\t//g'| grep server_id`
    var_lib_asterisk_agin_bin_mor_conf_server_id=`awk -F"#|;" '{ print $1}' /var/lib/asterisk/agi-bin/mor.conf | sed 's/ //g' |  sed 's/\t//g'| grep server_id`
    
    if [ "$etc_asterisk_mor_conf_server_id" == "$var_lib_asterisk_agin_bin_mor_conf_server_id" ]; then
        return 0;
    else
        return 1;
    fi
}

fix_server_id_in_var_lib_asterisk_agin_bin_mor_conf()
{
    mkdir -p /usr/local/mor/backups/etc/asterisk
    _mor_time
    cp /var/lib/asterisk/agi-bin/mor.conf /usr/local/mor/backups/etc/asterisk/var_lib_asterisk_agi_bin_mor_conf_$mor_time
    replace_line /var/lib/asterisk/agi-bin/mor.conf server_id "$etc_asterisk_mor_conf_server_id"
}


#--------MAIN -------------

asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0;
fi

check_if_server_id_match
if [ "$?" == "0" ]; then
    report "server_id in /var/lib/asterisk/agi-bin/mor.conf and /etc/asterisk/mor.conf match" 0
else
    fix_server_id_in_var_lib_asterisk_agin_bin_mor_conf
    check_if_server_id_match
    if [ "$?" == "0" ]; then
        report "server_id in /var/lib/asterisk/agi-bin/mor.conf and /etc/asterisk/mor.conf fixed to match the one defined in /etc/asterisk/mor.conf" 4
    fi

fi





