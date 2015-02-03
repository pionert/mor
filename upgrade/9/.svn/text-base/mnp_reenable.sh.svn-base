#!/bin/sh

# run this file after fix_trunk.sh IF client has MNP addon installed, because fix_trunk.sh disables MNP addon

# includes
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh

/usr/bin/mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" -e "UPDATE mor.extlines SET app = 'AGI', appdata = 'mor_mnp' WHERE extlines.context = 'mor' AND extlines.exten = '_X.' AND extlines.priority =1;"
