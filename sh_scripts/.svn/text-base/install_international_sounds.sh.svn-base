#! /bin/sh

. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh

rm /usr/src/asterisk_international_sounds.tgz
download_packet asterisk_international_sounds.tgz
extract_gz asterisk_international_sounds.tgz
cp -fr /usr/src/asterisk_international_sounds/* /var/lib/asterisk/sounds
