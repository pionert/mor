#!/bin/bash

# upgrades to Asterisk 1.4.42

#========= includes =========
   cd /usr/src/mor
   . "$(pwd)"/sh_scripts/mor_install_functions.sh
   . "$(pwd)"/sh_scripts/install_configs.sh
   . /usr/src/mor/test/framework/bash_functions.sh
#============================

if [ -f "/usr/lib/asterisk/modules/chan_zap.so" ]; then
    echo
    echo "Sorry, this Asterisk upgrade script does not support Zaptel upgrade..."
    echo
    exit 1;
fi

asterisk_rpms   # exit if asterisk RPMs detected. Reinstall is needed. Function is located at bash_functions.sh

ASTERISK_VER="1.4.42"
ADDONS_VER="1.4.11"

#download
download_packet asterisk-"$ASTERISK_VER".tar.gz
download_packet asterisk-addons-"$ADDONS_VER".tar.gz 

extract_gz asterisk-"$ASTERISK_VER".tar.gz 
extract_gz asterisk-addons-"$ADDONS_VER".tar.gz 

#move away old links/dirs if they exist
mv /usr/src/asterisk /usr/src/asterisk_old
mv /usr/src/asterisk-addons /usr/src/asterisk-addons_old

#delete if movement failed
rm -fr /usr/src/asterisk
rm -fr /usr/src/asterisk-addons

#clean old module which can not be compiled correctly
rm -fr /usr/lib/asterisk/modules/app_voicemail.so
	        
#create new
ln -s /usr/src/asterisk-"$ASTERISK_VER" /usr/src/asterisk
ln -s /usr/src/asterisk-addons-"$ADDONS_VER" /usr/src/asterisk-addons

# h323 stuff
#PWLIBDIR=/usr/src/pwlib_v1_10_0
#export PWLIBDIR
#OPENH323DIR=/usr/src/openh323_v1_18_0/
#export OPENH323DIR

#dirty hack to prevent error from missing file
cd /usr/include/linux
touch compiler.h

download_packet pwlib-v1_10_0-src-tar.gz;
extract_gz pwlib-v1_10_0-src-tar.gz

cd /usr/src/pwlib_v1_10_0/
./configure
make
make install
make opt
PWLIBDIR=/usr/src/pwlib_v1_10_0
export PWLIBDIR

#OpenH323
download_packet openh323-v1_18_0-src-tar.gz
extract_gz openh323-v1_18_0-src-tar.gz

cd /usr/src/openh323_v1_18_0/
./configure
make
make opt
make install
OPENH323DIR=/usr/src/openh323_v1_18_0/
export OPENH323DIR


#fix some patching problems
mv /usr/src/asterisk/channels/chan_sip.patched.c /usr/src/asterisk/channels/chan_sip.c_patched

#new module.conf with smdi support
cp -fr /usr/src/mor/asterisk-conf/9/modules.conf /etc/asterisk/

#install
#cp -fr /usr/src/mor/asterisk-addons/patch_v"$ASTERISK_VER"/* /usr/src/asterisk/
cd /usr/src/asterisk/channels/h323
make opt
cd /usr/src/asterisk
./configure
make
make install

#copy makefile changes and recompile
/bin/cp -r /usr/src/mor/asterisk-addons/1.4/* /usr/src/asterisk-addons
cd /usr/src/asterisk-addons
./configure
make
make install

#nv_faxdetect rxfax txfax
cd /usr/src/mor/fax2email/additional_apps
make clean
make
make install

/bin/cp -fr /usr/src/mor/asterisk-conf/cdr.conf /etc/asterisk

#restart asterisk
cd /usr/src/mor/sh_scripts
./asterisk_nice_restart.sh

asterisk_current_version #getting current asterisk version
STATUS="$?"
if [ "$STATUS" == "1" ]; then
    report "!!!!!!!!!! Problems detected with Asterisk after upgrade!!!!!" 1
else
    if [ "$ASTERISK_VER" == "$ASTERISK_VERSION" ]; then
        report "Asterisk was successfully upgraded to $ASTERISK_VERSION" 0
        echo -e  "\n\n\nAsterisk $ASTERISK_VER installed with Addons $ADDONS_VER \n\n"
        echo -e ">>>>> Do not forget to recompile app_mor.so AND compile it to support new Asterisk version! <<<<<<<<\n\nPress ENTER to finish"
        read
    else
        report "Asterisk upgrade FAILED. Asterisk should have $ASTERISK_VER version, now it has $ASTERISK_VERSION version!" 1
    fi
fi

