#!/bin/sh

# includes
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh


rm -fr /usr/src/mor2
mv /usr/src/mor /usr/src/mor2
/usr/src/mor2/sh_scripts/upgrade_install_script.sh
/usr/src/mor/upgrade/9/fix.sh

# will install 2 channel limited app_mor.so version
install_app_mor;
