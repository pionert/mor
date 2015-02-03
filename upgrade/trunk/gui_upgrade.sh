#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
    . /usr/src/mor/test/framework/bash_functions.sh
#=================================================

#make backup of previous gui
_mor_time; #get the system time
tar czf /usr/local/mor/backups/GUI/mor_gui_backup.$mor_time.tar.gz /home/mor/app /home/mor/config /home/mor/doc /home/mor/lang /home/mor/lib /home/mor/public/stylesheets /home/mor/vendor 


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

      svn co http://svn.kolmisoft.com/mor/gui/trunk /tmp/mor ;
      cp -f -r -v /tmp/mor /home/ 
      rm -rf /tmp/mor 

chmod -R 777 /home/mor/public/images/logo /home/mor/public/images/cards 

if [ -d /home/mor/public/ad_sounds ]; then
    chmod 777 /home/mor/public/ad_sounds
else
    mkdir -p /home/mor/public/ad_sounds
    chmod 777 /home/mor/public/ad_sounds    
    ln -s /home/mor/public/ad_sounds /var/lib/asterisk/sounds/mor/ad
fi

rm -rf /tmp/mor 

#apache_restart;


if [ -r /etc/redhat-release ]; then
  /etc/init.d/httpd restart
 else
    /etc/init.d/apache2 restart
fi;
log_revision 'mor' 'gui' 'Update was made using gui_upgrade.sh'
