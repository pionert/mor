#! /bin/sh

. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh

rm /usr/src/mor_sounds.tgz
download_packet mor_sounds.tgz
extract_gz mor_sounds.tgz
cp -fr /usr/src/sounds/* /var/lib/asterisk/sounds
