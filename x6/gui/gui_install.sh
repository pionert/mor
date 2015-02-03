#!/bin/bash

source "/etc/profile.d/rvm.sh"


    if [ ! -f /etc/yum.repos.d/epel.repo ]; then
        report "Epel repo not found, installing epel repo" 3
        _centos_version
        if [ "$centos_version" == "5" ]; then
            rpm -Uvh http://mirror.duomenucentras.lt/epel/5/i386/epel-release-5-4.noarch.rpm
        else
            rpm -Uvh http://mirror.duomenucentras.lt/epel/6/i386/epel-release-6-8.noarch.rpm
        fi

        if [ ! -f /etc/yum.repos.d/epel.repo ]; then
            report "Failed to install epel repo. Most probably version number changed, try to install manually by increasing version number in this command: rpm -Uvh http://mirror.duomenucentras.lt/epel/6/i386/epel-release-6-8.noarch.rpm    and run the script again"
        fi
    fi

    yum --enablerepo=epel install -y mysql-devel


stable_rev=`cat /usr/src/mor/x6/stable_revision`
svn co -r $stable_rev http://svn.kolmisoft.com/mor/gui/branches/x6 /home/mor

ln -s /home/mor/public /var/www/html/billing

rvm use 2.1.2
cd /home/mor
bundle update

cp -fr /usr/src/mor/x6/gui/gui_config_files/environment.rb /home/mor/config
cp -fr /usr/src/mor/x6/gui/gui_config_files/database.yml /home/mor/config



mkdir -p /var/log/mor
touch /var/log/mor/gui_debug.log
chmod 666 /var/log/mor/gui_debug.log
touch /var/log/mor_gui_crash.log
chmod 666 /var/log/mor_gui_crash.log

mkdir -p /home/mor/log
touch /home/mor/log/production.log
chmod 666 /home/mor/log/production.log
touch /home/mor/log/development.log
chmod 666 /home/mor/log/development.log

mkdir -p /home/mor/tmp
chmod 777 /home/mor/tmp

chmod 777 -R /home/mor/public/images/logo

/etc/init.d/httpd restart

# install cronjobs
cp -fr /usr/src/mor/x6/gui/cronjobs/* /etc/cron.d/
/etc/init.d/crond restart

