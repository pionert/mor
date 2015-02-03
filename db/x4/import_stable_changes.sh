#! /bin/sh
#==== Includes=====================================
   cd /usr/src/mor
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
    . /usr/src/mor/test/framework/bash_functions.sh
#==================================================

get_last_stable_mor_revision x4
svn update -r $LAST_STABLE_GUI http://svn.kolmisoft.com/mor/install_script/trunk/db/x4/ /usr/src/mor/db/x4/ &> /dev/null

echo "Latest stable revision: $LAST_STABLE_GUI"

/usr/src/mor/db/x4/import_changes.sh
