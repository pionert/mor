#!/bin/bash

DEBUG="0";  #{ "1" - show calculated ram amount, "0" - NO debug info}
. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh
export PATH="/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"

#-------- Percentage (%) values for various settings. All values must be from range 1.00 - 80.00 -----------

PERCENT_join_buffer_size="0.39"
PERCENT_innodb_buffer_pool_size="12.5"      # don't touch this one. Giving too much RAM causes MySQL to timeout when starting, because initializing assigned RAM for this parameter is a very long taking process
PERCENT_key_buffer="0.78"
PERCENT_thread_stack="0.03"

#--- Non percent based optimization values

M_thread_cache_size="4"     # default - 4. Should be tuned
M_table_cache="128"         # for how many tables to keep cache? 
query_cache_size="250M"     # fixed value because percentage does not work well on systems with lot of RAM
query_cache_limit="30M"     # fixed value because percentage does not work well on systems with lot of RAM

max_allowed_packet="999M"   # Don't touch this one

#-------- STATIC values for various settings in MB--------------

read_mor_db_settings

if [ "$DB_PRESENT" == "0" ]; then
    report "Database is not present. No need to run this script. If this server contains database, please update /etc/mor/db.conf" 3
    exit 0;
fi

if [ ! -f /usr/bin/bc ]; then
    yum -y install bc   #for math in bash
fi

#============================================== MAIN =========================================================================
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
#-----------
calculate_ram_amount()
{
    #Arguments
        #1 - total RAM
        #2 - percent of RAM
    #Returns:
        #$AMOUNT_OF_RAM - the calculated amount of RAM (integer value)

    if [ ! -x "/usr/bin/bc" ]; then
        yum -y install bc
        if [ ! -x "/usr/bin/bc" ]; then
            echo "Failed to install bc, cannot continue";
            exit 1;
        fi
    fi
    #-----------------------------------------------------------
    AMOUNT_OF_RAM=`echo "scale=0; $1*$2/100" | bc 2>&1`
    if [ "$AMOUNT_OF_RAM" == "0" ]; then    #if calculation failed
        #echo "An error encountered during the calculation of RAM in function calculate_ram_amount with parameters: 1: $1, 2:$2"
        #echo "Further proceeding can lead to undesirable results, exiting while it is safe"
        AMOUNT_OF_RAM=1
        if [ "$DEBUG" == "1" ]; then echo "\$AMOUNT_OF_RAM="$AMOUNT_OF_RAM;        fi

    fi
}
#-----
backup_my_cnf()
{
    mor_time=`date +%Y\.%-m\.%-d\-%-k\-%-M\-%-S`;
    echo "Backing up your current /etc/my.cnf config to /usr/local/mor/backups/my_cnf/my.cnf_$mor_time"
    mkdir -p /usr/local/mor/backups/my_cnf
    cp /etc/my.cnf /usr/local/mor/backups/my_cnf/my.cnf_$mor_time
}
#-----
replace_setting_if_different_or_none()
{
    #arguments
        #1 - setting to check if exist
        #2 - setting to replace with if 1 and 2 are different

    if [ "$1" == "skip-bdb" ]; then
        CURRENT_SETTING=`awk -F "#" '{print $1}' /etc/my.cnf | sed 's/ //g' | grep "$1" ` 
    else
        CURRENT_SETTING=`awk -F "#" '{print $1}' /etc/my.cnf | sed 's/ //g' | grep "$1=" | head -n 1` 
    fi    
    
    if [ "$CURRENT_SETTING" == "" ]; then
        echo "$CURRENT_SETTING"
        insert_line_after_pattern "\[mysqld\]" "$2" "/etc/my.cnf"
        echo -e "[\E[33mAdded \E[33m\033[0m]\t$2";
        RESTART_REQUIRED="yes"
    elif [ ! "$CURRENT_SETTING" == "$2" ]; then
        sed "/.*$1/d" /etc/my.cnf >/tmp/my_cnf1 ; mv /tmp/my_cnf1 /etc/my.cnf
        insert_line_after_pattern "\[mysqld\]" "$2" "/etc/my.cnf"        
        echo -e "[\E[33mUpdated \E[33m\033[0m]\t$2";
        RESTART_REQUIRED="yes"
    elif [ "$CURRENT_SETTING" == "$2" ]; then
        echo -e "[\E[32m   OK   \E[32m\033[0m]\t$2";
    fi
}
#============================================================================================================================

if [ ! -r "/etc/redhat-release" ]; then
    echo "Sorry, but currently MOR supports only CentOS";
fi
#===== SYSTEM =====
#-- RAM
set $(free -m)
TOTAL_RAM="$8"  #Total RAM in MB

#-- Processors
processor_count=`egrep -c $'^processor[ \t]+:' /proc/cpuinfo`
processor_count=$((processor_count*2))

#================= Calculate correct RAM amounts for current system hardware======================

calculate_ram_amount $TOTAL_RAM $PERCENT_join_buffer_size "join_buffer_size"
    join_buffer_size='join_buffer_size='$AMOUNT_OF_RAM'M'

thread_cache_size='thread_cache_size='$M_thread_cache_size

calculate_ram_amount $TOTAL_RAM $PERCENT_innodb_buffer_pool_size "innodb_buffer_pool_size"
    # MySQL has a bug in RAM memory initialization - if a lot of RAM is allocated for this setting - it takes a lot for MySQL to start and MySQL gives up as Timeout occours. Currently there is no setting to change this. To prevent this we do not allow to allocate more than 1024 MB
    if [ "$AMOUNT_OF_RAM" -gt "512" ]; then
        AMOUNT_OF_RAM="512"
    fi
    innodb_buffer_pool_size='innodb_buffer_pool_size='$AMOUNT_OF_RAM'M'

table_cache='table_cache='$M_table_cache

calculate_ram_amount $TOTAL_RAM $PERCENT_key_buffer "key_buffer"
    key_buffer='key_buffer='$AMOUNT_OF_RAM'M'

calculate_ram_amount $TOTAL_RAM $PERCENT_thread_stack "thread_stack"
    thread_stack='thread_stack='$AMOUNT_OF_RAM'M'

#======================================================================================
RESTART_REQUIRED="NO"  # resetting

backup_my_cnf

replace_setting_if_different_or_none "query_cache_size" "query_cache_size=$query_cache_size"
replace_setting_if_different_or_none "join_buffer_size" "$join_buffer_size"
replace_setting_if_different_or_none "thread_cache_size" "$thread_cache_size"
replace_setting_if_different_or_none "innodb_buffer_pool_size" "$innodb_buffer_pool_size"
replace_setting_if_different_or_none "table_cache" "$table_cache"
replace_setting_if_different_or_none "max_allowed_packet" "max_allowed_packet=$max_allowed_packet"
replace_setting_if_different_or_none "thread_concurrency" "thread_concurrency=$processor_count"

_mysql_version=`mysql --version | grep -o "Distrib [0-9.]*" | awk '{print $2}'`   #for compatibility with newer mysql versions
ruby /usr/src/mor/test/framework/which_version_is_bigger.rb "5.0.9" $_mysql_version
if [ "$?" == "1" ]; then
        replace_setting_if_different_or_none "skip-bdb" "skip-bdb"
else

    mysql_server_version
    if [ "$MYSQL_VERSION_2" == "5.5" ]; then
        if [ `grep skip-bdb /etc/my.cnf | wc -l` -gt "0" ]; then
            temp=`mktemp`
            sed '/skip-bdb/d' /etc/my.cnf > $temp;
            mv $temp /etc/my.cnf
            RESTART_REQUIRED="yes"
            echo -e "[\E[33mUpdated \E[33m\033[0m]\tskip-bdb option removed";
        fi
    fi
fi

replace_setting_if_different_or_none "key_buffer" "$key_buffer"
replace_setting_if_different_or_none "thread_stack" "$thread_stack"
replace_setting_if_different_or_none "query_cache_limit" "query_cache_limit=$query_cache_limit"

if [ "$RESTART_REQUIRED" = "yes" ]; then
    /etc/init.d/mysqld restart
fi
