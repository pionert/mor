#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

install_additional_repositories()
{
    # Author:   Mindaugas Mardosas
    # Year:     2012
    # About:    This script installs epel and remi repositories in order to install mysql 5.5
    _centos_version
    echo $centos_version
    if [ "$centos_version" == "5" ]; then
        rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
        rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-5.rpm
    else    # centos 6
        rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
        rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
    fi
}

install_mysql_5_5()
{
    report "Installing MySQL 5.5" 3
    _centos_version
    if [ "$centos_version" == "5" ]; then
        yum -y --nogpgcheck --enablerepo=remi,remi-test install mysql mysql-server
    else    # centos 6
        yum -y --nogpgcheck --releasever=6 --enablerepo=remi,remi-test install mysql mysql-server
    fi
    if [ "$?" == "0" ]; then
        report "MySQL 5.5 was successfully installed/updated" 4
    else
        report "Failed to install/update MySQL 5.5 " 1
    fi
}
upgrade_tables()
{
    report "Upgrading MySQL tables to be compatible with current MySQL version" 3
    mysql_upgrade
    if [ "$?" != "0" ]; then
        report "Please provide MySQL root password" 3
        mysql_upgrade -u root -p
    fi

}

#--------MAIN -------------

service mysqld stop
install_additional_repositories
install_mysql_5_5
service mysqld start
upgrade_tables
# reconfigure mysql
sh /usr/src/mor/sh_scripts/configure_mycnf.sh
