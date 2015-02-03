#! /bin/sh
# Author:   Mindaugas Mardosas
# Year:     2012
# About:    This script adds  innodb_file_per_table=1 option to /etc/my.cnf. It results in better performance when using big databases.
#
# Arguments:
#   "RESTART" - Restart MySQL if option is added


if [ "$1" == "RESTART" ]; then
    RESTART_NEEDED=1; # restart MySQL
fi


. /usr/src/mor/x6/framework/bash_functions.sh

export PATH="/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"




insert_line_after_pattern()
{	#special characters need to be escaped like:   \$
	#arg1 - pattern
	#arg2 - what to add
	#arg3 - path to file
	#example: insert_line_after_pattern "\[mysqld\]" "max_allowed_packet=100M" "/etc/my.cnf"

	if [ ! -f "$3" ]; then return 1; fi

	awk -F"#" '{print $1}' "$3" | sed 's/ //g' | grep "$2" &> /dev/null
	if [ "$?" == "0" ]; then
		echo -e "[\E[33m  ALREADY EXIST \E[33m\033[0m]\t$2";
	else
		cp $3 $3.mor_backup;
		sed '/'$1'.*$/a\'$2'' "$3" > /tmp/.mor_tmp && cat /tmp/.mor_tmp > "$3" && rm -rf /tmp/.mor_tmp
		#---------
		cat "$3" | grep "$2" &> /dev/null
		if [ $? != 0 ]; then
			echo -e "[\E[31m FAILED \E[31m\033[0m]\t$2";
		fi
	fi
}

check_if_file_per_table_option_present()
{
    # Author:   Mindaugas Mardosas
    # Year:     2012
    # About:    This function checks is MySQL has enabled option for one file/table
    #
    # Returns:
    #   FILE_PER_TABLE {0 - option not present, 1 - option is present}

    FILE_PER_TABLE=`grep innodb_file_per_table /etc/my.cnf | wc -l`
}

#----------------- MAIN --------------

check_if_file_per_table_option_present
if  [ "$FILE_PER_TABLE" == "0" ]; then
    insert_line_after_pattern "\[mysqld\]" "innodb_file_per_table=1" "/etc/my.cnf"
    check_if_file_per_table_option_present
    if  [ "$FILE_PER_TABLE" == "1" ]; then
        report "Added option innodb_file_per_table=1 to /etc/my.cnf, this option results in better performance when working with larger databases" 4
        
        if [ "$RESTART_NEEDED" == "1" ]; then
            report "Restarting MySQL" 3
            /etc/init.d/mysqld restart
        fi
    else
        report "Failed to add innodb_file_per_table=1 to /etc/my.cnf" 1
    fi
else
    report "innodb_file_per_table=1 is present in /etc/my.cnf" 0
fi