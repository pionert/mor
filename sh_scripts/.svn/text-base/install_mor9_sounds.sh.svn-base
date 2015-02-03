#! /bin/sh

# includes
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh

rm -f /usr/src/mor9_sounds.tgz
download_packet mor9_sounds.tgz
extract_gz mor9_sounds.tgz

cp -ru /usr/src/sounds/digits/* /var/lib/asterisk/sounds/digits
cp -ru /usr/src/sounds/mor/ivr_voices/* /home/mor/public/ivr_voices/

# ivr fix
chmod 777 /home/mor/public
chmod 777 /home/mor/public/ivr_voices
chmod 755 -R /home/mor/public/ivr_voices
chmod 777 /var/lib/asterisk/sounds/mor/
chmod 777 /var/lib/asterisk/sounds/
chmod 777 /var/lib/asterisk/
chmod 777 /var/lib/
chmod 777 /var/
chown -R apache: /home/mor/public/ivr_voices

