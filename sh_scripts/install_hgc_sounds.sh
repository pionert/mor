#! /bin/sh

. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh

download_packet mor_sounds_hgc.tgz
extract_gz mor_sounds_hgc.tgz
mkdir -p /var/lib/asterisk/sounds/mor/hgc/
cp -r /usr/src/hgc/* /var/lib/asterisk/sounds/mor/hgc/
