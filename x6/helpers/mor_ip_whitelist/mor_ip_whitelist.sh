#!/bin/sh

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2014
# About:    Script creates IPs whitelist which contains IPs of IP authenticated MOR Device and Providers. It works by adding "MOR-IPAUTH-WHITELIST" chain to iptables and listing allowed IPs there.

. /usr/src/mor/x6/framework/bash_functions.sh

# script is started by cron. To avoid queries burst let it sleep random seconds before going futher
sleep $[ ( $RANDOM % 29 )  + 1 ]s

# create "MOR-IPAUTH-WHITELIST" chain if it does not exist
/sbin/iptables -L -n | grep "Chain MOR-IPAUTH-WHITELIST" &> /dev/null
if [ "$?" != "0" ]; then
    /sbin/iptables -N MOR-IPAUTH-WHITELIST
    /sbin/iptables -I INPUT 1 -j MOR-IPAUTH-WHITELIST
fi

# make sure that we can access database
mysql_connect_data_v2 &> /dev/null
if [ "$?" != "0" ]; then
    report "Failed to retrieve database connection details" 1
    exit 1;
fi

# cleanup previous list
/sbin/iptables -F MOR-IPAUTH-WHITELIST
/sbin/iptables -A MOR-IPAUTH-WHITELIST -j RETURN

# retrieve and add IPs
for x in `/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" --password=$DB_PASSWORD "$DB_NAME" --disable-column-names -B -e 'SELECT DISTINCT host FROM devices WHERE host NOT IN ("0.0.0.0","dynamic","127.0.0.1") AND host NOT LIKE "%-%"'`; do
#echo "adding $x"
    /sbin/iptables -I MOR-IPAUTH-WHITELIST -s $x -j ACCEPT
done

# fail2ban moves its chains to the top of INPUT chain. Make sure that "MOR-IPAUTH-WHITELIST" chain is above fail2ban chains.
CHAIN_PRIORITY=`/sbin/iptables -L -n --line-numbers | grep MOR-IPAUTH | grep -v "Chain" | awk '{print $1}'`
if [ "$CHAIN_PRIORITY" == "1" ]; then
    # chain priority is OK
    exit 0;
elif [ "$CHAIN_PRIORITY" -gt "1" ] && [ "$CHAIN_PRIORITY" -lt "1" ] ; then
    # lets fix chain priority
    /sbin/iptables -D INPUT -j MOR-IPAUTH-WHITELIST
    /sbin/iptables -I INPUT 1 -j MOR-IPAUTH-WHITELIST
else
    report "Failed to determine chain priority" 1
    exit 1;
fi
