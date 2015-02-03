#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
    . /usr/src/mor/test/framework/bash_functions.sh
#==================================================

#make backup of previous gui
_mor_time; #get the system time
tar czf /usr/local/mor/backups/GUI/mor_gui_backup.$mor_time.tar.gz /home/mor/app /home/mor/config /home/mor/doc /home/mor/lang /home/mor/lib /home/mor/public/stylesheets /home/mor/vendor 

svn co http://svn.kolmisoft.com/mor/gui/branches/8 /home/mor
#apache_restart;

chmod -R 777 /home/mor/public/images/logo /home/mor/public/images/cards

if [ -r /etc/redhat-release ]; then
  /etc/init.d/httpd restart
else
    /etc/init.d/apache2 restart
fi;
log_revision 'mor' 'gui' 'Update was made using gui_upgrade_light.sh'
