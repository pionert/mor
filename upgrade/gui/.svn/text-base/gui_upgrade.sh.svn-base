#!/bin/sh
#================== includes ======
   cd /usr/src
   . "$(pwd)"/sh_scripts/install_configs.sh
#=====================

if [ $LOCAL_INSTALL == 0 ]; then
   if [ -r /etc/redhat-release ]; then 
       yum install -y subversion
   else
       apt-get update
       apt-get -y install subversion
   fi;
fi

rm -r /tmp/mor 
svn co http://svn.kolmisoft.com/mor/gui/branches/0.6 /tmp/mor
cp -f -r -v /tmp/mor /home/ 
rm -r /tmp/mor 
chmod 777 /home/mor/public/images/logo 
chmod 777 /home/mor/public/images/logo/* 
chmod 777 /home/mor/public/ad_sounds


if [ -r /etc/redhat-release ]; then 
    /etc/init.d/httpd restart
else
    /etc/init.d/apache2 restart 
fi;

