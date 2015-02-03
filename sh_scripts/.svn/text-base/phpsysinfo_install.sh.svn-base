#!/bin/sh


#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#====end of Includes===========================
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


fi;
