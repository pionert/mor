#!/bin/bash
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#====end of Includes===========================

#== Don't touch these===
which_os #needed to detect CentOS
_mor_time;
#=======================

#==== FUNCTIONS

asterisk_logger_cfg()
{
    NEED_TO_UPDATE_LOGGER_CFG=0;

    grep "dateformat=%F %T" /etc/asterisk/logger.conf
    if [ "$?" != "0" ]; then
        NEED_TO_UPDATE_LOGGER_CFG=1;
    fi

    grep "messages => notice, warning, error" /etc/asterisk/logger.conf
    if [ "$?" != "0" ]; then
        NEED_TO_UPDATE_LOGGER_CFG=1;
    fi

    if [ "$NEED_TO_UPDATE_LOGGER_CFG" == "1" ]; then
        echo -e "Setting up /etc/asterisk/logger.conf"
        mv /etc/asterisk/logger.conf /etc/asterisk/logger.conf_$mor_time
        echo -e "[general]\ndateformat=%F %T\n[logfiles]\n;debug => debug\nconsole => notice,warning,error\nmessages => notice, warning, error\n;full => notice, warning, error, debug, dtmf" > /etc/asterisk/logger.conf
        asterisk -rx "logger reload"
        echo "[FIXED] /etc/asterisk/logger.conf"
    else
        echo "[OK] /etc/asterisk/logger.conf"
    fi
}

backup_fail2ban_cfg()
{
    if [ -d "/etc/fail2ban" ]; then

        mkdir -p /usr/local/mor/backups/fail2ban
        tar czf /usr/local/mor/backups/fail2ban/fail2ban_mor_cfg_backup_$mor_time.tar.gz /etc/fail2ban
        echo "[BACKUP MADE] fail2ban_mor_cfg_backup_$mor_time.tar.gz"
    fi
}

check_if_asterisk_installed()
{
    if [ ! -d "/etc/asterisk" ]; then
        echo "[FATAL ERROR] Asterisk is not installed in this server"
        exit 1
    else
        echo "[OK] /etc/asterisk found"
    fi
}

check_if_iptables_installed()
{
    if [ ! -f "/sbin/iptables" ]; then
        printf '\e[5;32;40m WARNING: iptables is not installed\e[m\n'
        echo -e "[FAILED] iptables are not installed\nTrying to install"
        yum -y install iptables
        iptables -F
        /etc/init.d/iptables save
    else
        mkdir -p /usr/local/mor/backups/iptables
        iptables-save >/usr/local/mor/backups/iptables/mor_iptables_backup_$mor_time.txt;
        echo -e "[BACKED UP EXISTING IPTABLES RULES] /usr/local/mor/backups/iptables/mor_iptables_backup_$mor_time.txt;"
    fi
}

install_fail2ban_if_not_exist()
{
    echo "Installing fail2ban"
    yum -y install gamin gamin-python
    rm -rf /usr/src/fail2ban-0.8.4.tar.gz /usr/src/fail2ban-0.8.4
    download_packet "fail2ban-0.8.4.tar.gz"
    #cd /usr/src

    if [ ! -d "/usr/src/fail2ban-0.8.4" ]; then
        tar xvfz fail2ban-0.8.4.tar.gz
        cd fail2ban-0.8.4
        python setup.py install
        cp /usr/src/fail2ban-0.8.4/files/redhat-initd /etc/init.d/fail2ban
        chmod 755 /etc/init.d/fail2ban


        chkconfig --add fail2ban
        chkconfig --level 2345 fail2ban on
    fi
}
start_add_fail2ban()
{
    service fail2ban restart #butinai restart
}

addresses_to_ignore()
{

IGNORE_ADDRESSES="192.168.0.1/16 10.0.0.0/8 127.0.0.1/8 172.16.0.0/12 213.197.141.162 "

ifconfig | sed -n '/^[A-Za-z0-9]/ {N;/dr:/{;s/.*dr://;s/ .*//;p;}}' | while read IP; do
    echo -n " $IP" >> /tmp/._mor_fail2ban_addr_to_ignore_$mor_time.txt
done

OTHER_ADDRESSES=`cat /tmp/._mor_fail2ban_addr_to_ignore_$mor_time.txt`
rm -rf /tmp/._mor_fail2ban_addr_to_ignore_$mor_time.txt #clean

cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf_backup_$mor_time

ruby /usr/src/fail2ban-0.8.4/files/change_first_found_param_in_file.rb /etc/fail2ban/jail.conf "ignoreip =" "ignoreip = 192.168.0.1/16 10.0.0.0/8 127.0.0.1/8 172.16.0.0/12 213.197.141.162 $OTHER_ADDRESSES"

}

#============== MAIN =======================


if [ "$OS" = "CENTOS" ]; then
    check_if_asterisk_installed;
    backup_fail2ban_cfg;
    check_if_iptables_installed
    asterisk_logger_cfg
    install_fail2ban_if_not_exist
    addresses_to_ignore
    start_add_fail2ban
else
    echo "This script supports only CentOS, get it at http://centos.org"
fi

