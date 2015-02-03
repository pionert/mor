#! /bin/sh
#   Author: Mindaugas Mardosas, Nerijus Sapola
#   Year:   2010, 2012
#   About:  This script checks MySQL replication status if it is present

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

mm_replication_test()
{
#   Author: Mindaugas Mardosas, Nerijus Sapola
#   Year:   2010-2012
#   About:  This function checks MySQL replication status in case of Master<>Master replication. Status on all replicated databases are checked.

    config="/etc/my.cnf"
    if [ -r "$config" ]; then
        if [ -r "/var/lib/mysql/master.info" ]; then
            DB_HOST=`awk '{ if (NR==4) print $0 }' /var/lib/mysql/master.info`;
            DB_NAME=`grep replicate-do-db $config | grep -v '^#' | sed 's/ //g' | awk -F= '{print $2}' | awk '{printf "%s " ,$1}'`;
            DB_USERNAME=`awk '{ if (NR==5) print $0 }' /var/lib/mysql/master.info`;
            DB_PASSWORD=`awk '{ if (NR==6) print $0 }' /var/lib/mysql/master.info`;
        else
            report "Cannot read /var/lib/mysql/master.info to check replication status" 1
        fi
    fi
    
    DATABASES=($DB_NAME)
    for element in $(seq 0 $((${#DATABASES[@]} - 1)))
    do
            conn=`/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" ${DATABASES[$element]} -e "SHOW SLAVE STATUS\G" &> /dev/null`
            if [ "$?" != "0" ]; then
                report "Error encountered when connecting to Master database" 1
                return 1;
            fi

            REPLICATION=`/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password="$DB_PASSWORD" ${DATABASES[$element]} -e "SHOW SLAVE STATUS\G" | grep -e Slave_IO_Running -e Slave_SQL_Running | awk '{printf $2}'`
            # sitas grazins YesYes jei veikia rep
            if [ $REPLICATION != "YesYes" ] ; then
                report "MySQL replication is not running" 1
                return 1;
            fi
              
    done
    report "Replication is running" 0
    return 0;           
}

ms_replication_test()
{
#   Author: Mindaugas Mardosas, Nerijus Sapola
#   Year:   2010-2012
#   About:  This function checks MySQL Master-->Slave replication status on Master server side.
#           Test is based on checking if Slave server is reading binlog. Slave server stops doing that on failure.
    
    mysql -e "SHOW PROCESSLIST" | grep 'Binlog Dump' &> /dev/null
    if [ "$?" == "0" ]; then
        report "Slave server is connected to current server." 0
        return 0;
    else
        report "Master-Slave replication is not running. Slave server is not connected." 1
    fi
}

sm_replication_test()
{
#   Author: Nerijus Sapola
#   Year:   2012
#   About:  This function checks MySQL Master-->Slave replication status on Slave server side.
#           Slave status is checked localy to find if replication is running.


    config="/etc/my.cnf"
    if [ -r "$config" ]; then
        DB_NAME=`grep replicate-do-db $config | grep -v '^#' | sed 's/ //g' | awk -F= '{print $2}' | awk '{printf "%s " ,$1}'`;
    fi
    
    DATABASES=($DB_NAME)
    for element in $(seq 0 $((${#DATABASES[@]} - 1)))
    do
            conn=`/usr/bin/mysql ${DATABASES[$element]} -e "SHOW SLAVE STATUS\G" &> /dev/null`
            if [ "$?" != "0" ]; then
                report "Error encountered when connecting to database" 1
                return 1;
            fi

            REPLICATION=`/usr/bin/mysql ${DATABASES[$element]} -e "SHOW SLAVE STATUS\G" | grep -e Slave_IO_Running -e Slave_SQL_Running | awk '{printf $2}'`
            # sitas grazins YesYes jei veikia rep
            if [ $REPLICATION != "YesYes" ] ; then
                report "Master-Slave replication is not running" 1
                return 1;
            fi
              
    done
    report "Master-Slave replication is running" 0
    return 0; 

}

#================= MAIN ====================

read_mor_replication_settings
if [ "$REPLICATION_PRESENT" == "no" ]; then
    report "Replication is not present" 3
    exit 0;                                    # there is nothing to check if replication is not present
elif [ "$REPLICATION_M" == "1" ] && [ "$REPLICATION_S" == "1" ]; then
    mm_replication_test
    exit $?;
elif [ "$REPLICATION_S" == "1" ]; then
    sm_replication_test
    exit $?
elif [ "$REPLICATION_M" == "1" ]; then
    ms_replication_test
    exit $?
else
    report "Failed to check Replication status!" 1   # it can only happen if read_mor_replication_settings function returns invalid values
fi

