#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#=================================================

#check for SVN, install if not available
SVN=`svn --version | grep 'CollabNet'`
if [ "$SVN" == "" ]; then
    echo -e "\nSubversion not found - installing...\n"
    if [ -r /etc/redhat-release ]; then 
	   yum install -y subversion
    else
	   apt-get update
	   apt-get -y install subversion
    fi
fi

rm -rf /tmp/mor

#      kolmi_ping $KOLMISOFT_IP; #ping'ing the server

#if [ $? == 0 ]; #if ping succeeded
#   then 
      svn co http://svn.kolmisoft.com/mor/gui/branches/0.7 /tmp/mor ;
      cp -f -r -v /tmp/mor /home/ 
      rm -rf /tmp/mor 
#   elif [ $? == 1 ]; then cp -R /usr/src/other/trunk_0_7/* /home/mor/;
#fi

      #chmod 777 /home/mor/public/images/logo 
      #chmod 777 /home/mor/public/images/cards
      #chmod 777 /home/mor/public/images/logo/* 

chmod 777 /home/mor/public/images/logo /home/mor/public/images/cards /home/mor/public/images/logo/* 

if [ -d /home/mor/public/ad_sounds ]; then
    chmod 777 /home/mor/public/ad_sounds
else
    mkdir -p /home/mor/public/ad_sounds
    chmod 777 /home/mor/public/ad_sounds    
    cp -f /usr/src/mor/mor_ad/silence1.wav /home/mor/public/ad_sounds/
    ln -s /home/mor/public/ad_sounds /var/lib/asterisk/sounds/mor/ad
fi

rm -rf /tmp/mor 

#apache_restart;


if [ -r /etc/redhat-release ]; then
  /etc/init.d/httpd restart
  else
    /etc/init.d/apache2 restart
fi;
