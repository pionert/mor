#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:	This script installs Percona toolkit

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------

#--------MAIN -------------

install_percona_toolkit()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2013
    #   About:  This function install Percona toolkit for online DB schema migration.
    
    if [ `/usr/bin/pt-online-schema-change --version | grep '2.2.3' | wc -l` == "0" ]; then
        report "Percona Toolkit not detected, will install now" 3
        cd /usr/src
        wget -c http://www.kolmisoft.com/packets/percona/percona-toolkit-2.2.3-1.noarch.rpm
        yum -y install --nogpgcheck percona-toolkit-2.2.3-1.noarch.rpm
        if [ `/usr/bin/pt-online-schema-change --version | grep '2.2.3' | wc -l` == "1" ]; then
            report "Percona Toolkit installed" 4
            exit 0
        else
            report "Percona Toolkit installation failed, will not attempt to migrate DB" 1
            exit 1
        fi
    else
    	exit 0
    fi    
}

install_percona_toolkit