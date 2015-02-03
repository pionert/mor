#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#=================================================

rm -r /tmp/mor 
svn co http://svn.kolmisoft.com/mor/gui/branches/0.6 /tmp/mor
cp -f -r -v /tmp/mor /home/ 
rm -r /tmp/mor 
chmod 777 /home/mor/public/images/logo 
chmod 777 /home/mor/public/images/cards
chmod 777 /home/mor/public/images/logo/* 
chmod 777 /home/mor/public/ad_sounds

apache_restart
