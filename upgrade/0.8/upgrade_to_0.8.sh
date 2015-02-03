#!/bin/sh
#========= includes =========
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#============================

#======== DB backup ============
#        mor_db_backup "before_upgrade_to_0.8_"
#===============================


# Upgrade DB
#cd /usr/src/mor/upgrade/0.8
#./upgrade_db.sh

#wait_user;

# Upgrade GUI from SVN
#cd /usr/src/mor/upgrade/0.8
#./gui_upgrade.sh

#wait_user;

# Various GUI upgrades
#cd /usr/src/mor/upgrade/0.8
#./various_gui_upgrades.sh

#wait_user;

# Various APP upgrades
#cd /usr/src/mor/upgrade/0.8
#./various_app_upgrades.sh

#wait_user;


# Upgrade Asterisk + Addons
#cd /usr/src/mor/upgrade/asterisk
#./asterisk_upgrade.sh

#wait_user;


cd /usr/src/mor/upgrade/0.8
./fix_0.8.sh
