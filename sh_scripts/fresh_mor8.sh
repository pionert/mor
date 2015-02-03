#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#====end of Includes===========================

    # fresh db
    cd /usr/src/mor/db/0.8/
    ./make_clean_mor8_db.sh
    
    # changes to db
    ./import_changes.sh
    
    # gui upgrade
    cd /home/mor
    ./gui_upgrade_light.sh
    
    
