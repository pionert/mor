#!/bin/sh

# Author:   Nerijus Sapola
# Company:  Kolmisoft
# Year:     2014
# About:    Script installs mor_ip_whitelist.sh and creates cronjob.

. /usr/src/mor/x5/framework/bash_functions.sh

cp -fr /usr/src/mor/x5/helpers/mor_ip_whitelist/mor_ip_whitelist.sh /usr/local/mor/
chmod +x /usr/local/mor/mor_ip_whitelist.sh
echo "*/15 * * * * root /usr/local/mor/mor_ip_whitelist.sh" > /etc/cron.d/mor_ip_whitelist
chmod 644 /etc/cron.d/mor_ip_whitelist
service crond restart
