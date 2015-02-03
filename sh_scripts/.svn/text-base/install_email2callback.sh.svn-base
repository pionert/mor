#!/bin/bash
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh

        if [ "$LOCAL_INSTALL" == "0" ]; then
                yum -y install postfix dovecot system-switch-mail system-switch-mail-gnome
        fi

        adduser callback -s /sbin/nologin
        mkdir -p /home/callback/Maildir
        chmod -R 700 /home/callback/Maildir
        cd $DEFAULT_DOWNLOAD_DIR;
        checkforp1=`cat /etc/postfix/main.cf | grep "myhostname = changethis.nforces.eu"`
        checkforp2=`cat /etc/postfix/main.cf | grep "myhostname = host.domain.tld"`

if [ "$checkforp1" == "myhostname = changethis.nforces.eu" ]; then
    exit 0;# already installed
elif [ "$checkforp2" == "myhostname = host.domain.tld" ]; then
    mkdir -p /usr/local/mor/backups
    mv /etc/postfix /usr/local/mor/backups
fi

download_packet postfix.tar.gz
extract_gz postfix.tar.gz

mv /usr/src/postfix /etc/postfix
checkforcallback=`cat /etc/aliases | grep "callback: \"|/usr/local/mor/mor_email2callback.sh\""`

if [ "$checkforcallback" == "callback: \"|/usr/local/mor/mor_email2callback.sh\"" ]; then
    exit
else
    echo "callback: \"|/usr/local/mor/mor_email2callback.sh\"" >> /etc/aliases
    newaliases
fi

if [ ! -a "/usr/local/mor/mor_email2callback.sh" ]; then
    cp -fr /usr/src/mor/sh_scripts/mor_email2callback.sh /usr/local/mor
fi

echo "Don't forget that you still need change main.cf myhostname & mydomain directives and then reloading postfix!"

chkconfig --add dovecot
chkconfig --add postfix

/etc/init.d/postfix start
