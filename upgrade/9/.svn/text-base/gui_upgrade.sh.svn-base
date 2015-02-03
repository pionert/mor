#!/bin/sh
#==== Includes=====================================
# includes
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh
. /usr/src/mor/test/framework/bash_functions.sh

#make backup of previous gui
_mor_time; #get the system time
tar czf /usr/local/mor/backups/GUI/mor_gui_backup.$mor_time.tar.gz /home/mor/app /home/mor/config /home/mor/doc /home/mor/lang /home/mor/lib /home/mor/public/stylesheets /home/mor/vendor 

if [ ! -f "/usr/bin/svn" ]; then
    yum install -y subversion
fi

rm -rf /tmp/mor

get_last_stable_mor_revision 9
svn co -r $LAST_STABLE_GUI http://svn.kolmisoft.com/mor/gui/branches/9 /tmp/mor ;
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



/etc/init.d/httpd restart

log_revision 'mor' 'gui' 'Update was made using gui_upgrade.sh'
