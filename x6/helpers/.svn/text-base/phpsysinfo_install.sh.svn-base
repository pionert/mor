#!/bin/sh


. /usr/src/mor/x6/framework/framework.conf
. /usr/src/mor/x6/framework/mor_install_functions.sh
. /usr/src/mor/x6/framework/bash_functions.sh


echo -e "\n======== phpSysInfo installation ========\n"


if [ -d /usr/src/phpsysinfo ]; then

    echo "phpSysInfo is allready installed..."

else

    FILE=phpSysInfo-3.0-RC6
	 
    download_packet $FILE.tar.gz

    cd /usr/src
    tar zxvf $FILE.tar.gz
    mv /usr/src/phpsysinfo/config.php.new /usr/src/phpsysinfo/config.php

    if [ -r /etc/redhat-release ]; then
        mv /usr/src/phpsysinfo /var/www/html/phpsysinfo    
    else
        mv /usr/src/phpsysinfo /var/www/phpsysinfo
    fi;

    report "phpsysinfo installed" 0

fi;
