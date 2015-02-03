#!/bin/bash

exec >  >(tee -a install.log)
exec 2> >(tee -a install.log >&2)

echo "Starting MOR X5 installation..."
echo `date`

src="/usr/src/mor/x5"


# check for rvm presence to detemrine if server is empty or not
if [ -f '/usr/local/rvm/bin/rvm' ]; then
    . /usr/src/mor/x5/framework/bash_functions.sh
    report "System is not empty, aborting installation" 6
    exit 0
fi

# system update
#yum -y update # need reboot after that

# checking if apache user exist. Related TRAC #10975
grep apache /etc/passwd &>/dev/null
if [ "$?" == "0" ]; then
    grep apache /etc/passwd | grep 1000 &>/dev/null
    if [ "$?" == "0" ]; then
        echo "Apache user already exist with incorrect UID. Please report to TRAC #10975"
    else
        echo "Apache user already exist. This is not minimal clean Centos install"
    fi
    echo "Press any key to Continue or CRTL+C to Cancel"
    read user_input;
fi

# for DB/GUI/CORE servers
# environment check
$src/maintenance/vm_detection.sh
$src/maintenance/dns_check.sh # todo: we should terminate if dns does not work

# environment preparation
$src/maintenance/time_sync.sh
echo `date` # after sync we will get better time
$src/maintenance/selinux_disable.sh
$src/maintenance/yum_updatesd_disable.sh
$src/maintenance/iptables_clean.sh
$src/maintenance/time_sync.sh
$src/maintenance/ssl_fix_heartbleed.sh
$src/maintenance/configuration_prepare.sh
$src/maintenance/folders_permissions_prepare.sh
#$src/maintenance/aliases_install.sh
$src/maintenance/packets_install.sh

# necessary for DB/GUI servers
$src/gui/rvm_install.sh
$src/gui/ruby_install.sh

# for DB server
$src/mysql/mysql_install.sh
$src/db/db_create.sh NEW

# for GUI server
$src/gui/apache_install.sh
$src/gui/passenger_install.sh
$src/gui/memcached_install.sh
$src/gui/gui_install.sh
$src/mysql/phpmyadmin_install.sh
#some scripts needs to use right version of ruby. Those will use following simlink which point to ruby-2.1.2@global which is right version in case of MOR X5:
ln -s /usr/src/mor/x5/gui/misc/mor_ruby /usr/local/mor/mor_ruby
chmod +x /usr/local/mor/mor_ruby

# Asterisk
$src/asterisk/asterisk_install.sh
$src/core/core_install_10cc.sh

# Helper packages
$src/helpers/lame_install.sh
$src/helpers/elunia_stats_install.sh
$src/helpers/fail2ban_install.sh
$src/helpers/iperf_install.sh
$src/helpers/phpsysinfo_install.sh
$src/helpers/mor_ip_whitelist/install_mor_ip_whitelist.sh

# Scripts
$src/scripts/scripts_install.sh
cp -f $src/scripts/backups/make_restore.sh /usr/local/mor/
cp -f $src/scripts/backups/make_backup.sh /usr/local/mor/

# Final touches
$src/maintenance/logrotates_enable.sh
$src/maintenance/permissions_post_install.sh
$src/maintenance/alias_activate.sh
$src/db/generate_uniquehash.sh

# major check/fix
$src/info.sh

echo `date`
