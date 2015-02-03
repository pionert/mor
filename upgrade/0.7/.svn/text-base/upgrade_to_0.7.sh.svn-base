#!/bin/sh
#========= includes =========
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#============================

mkdir -p /usr/local/mor
mkdir -p /usr/local/mor/backups

#======== DB backup ============
        mor_db_backup "before_upgrade_to_0.7_"
#===============================

if [ $UPGRADE_TO_8 == 0 ]; then

    if [ $INSTALL_DB == 1 ]; then
	# Upgrade DB
        cd /usr/src/mor/upgrade/0.7
        ./upgrade_db.sh

	wait_user;
    fi

fi


if [ $INSTALL_GUI == 1 ]; then
    # Upgrade GUI from SVN


    if [ $LOCAL_INSTALL == 0 ]; then
	cd /usr/src/mor/upgrade/0.7
        ./gui_upgrade.sh
	wait_user;
    fi


    # Various GUI upgrades
    cd /usr/src/mor/upgrade/0.7
    ./various_gui_upgrades.sh
    wait_user;
fi

if [ $INSTALL_APP == 1 ]; then
    # Various APP upgrades
    cd /usr/src/mor/upgrade/0.7
    ./various_app_upgrades.sh

    wait_user;
fi


# Upgrade Asterisk + Addons
#cd /usr/src/mor/upgrade/asterisk
#./asterisk_upgrade.sh

#wait_user;
