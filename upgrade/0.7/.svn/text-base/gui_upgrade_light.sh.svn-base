#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================
svn co http://svn.kolmisoft.com/mor/gui/branches/0.7 /home/mor
#apache_restart;

if [ -r /etc/redhat-release ]; then
  /etc/init.d/httpd restart
else
    /etc/init.d/apache2 restart
fi;
