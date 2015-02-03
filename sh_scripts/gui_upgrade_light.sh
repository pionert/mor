#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================

svn co http://svn.kolmisoft.com/mor/gui/branches/0.6 /home/mor

apache_restart;
