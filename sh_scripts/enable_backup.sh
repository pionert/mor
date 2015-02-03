#! /bin/sh

    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh


    cp -f /usr/src/mor/sh_scripts/backup/* /usr/local/mor
    cp -f /usr/src/mor/sh_scripts/mor_install_functions.sh /usr/local/mor

#    crontab_add "hourly_actions" "0 * * * * wget -o /dev/null -O /dev/null http://127.0.0.1/billing/callc/hourly_actions" "Hourly actions crontab installed"


    if [ $LOCAL_INSTALL == 0 ]; then
	/home/mor/gui_upgrade_light.sh
    fi
