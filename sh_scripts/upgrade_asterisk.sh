#!/bin/bash

# upgrades Asterisk

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

if [ -f "/usr/lib/asterisk/modules/chan_dahdi.so" ]; then
    echo
    echo "Sorry, this Asterisk upgrade script does not support DAHDI upgrade..."
    echo
    exit 1;
fi


asterisk_rpms   # exit if asterisk RPMs detected. Reinstall is needed. Function is located at bash_functions.sh

ASTERISK_VER="1.8.12.0"

# temporary
yum -y install  tar mysql-devel gcc gcc-c++ ncurses-devel bison openssl openssl-devel gnutls-devel zlib-devel ghostscript make subversion wget sox chkconfig vixie-cron which logrotate postfix lynx gzip bc libxml2-devel flex patch autoconf automake libtool

cd /usr/src/mor/sh_scripts/asterisk/
./srtp_install.sh

cd /usr/src/mor/sh_scripts/asterisk/
./spandsp_install.sh

procedure_1()
{
echo
}

#Note: Add-ons for Asterisk 1.8 and 10 can be installed from the "menuselect" menu. 
#ADDONS_VER="1.4.11"


#download
download_packet asterisk-"$ASTERISK_VER".tar.gz

extract_gz asterisk-"$ASTERISK_VER".tar.gz 

# move away old links/dirs if they exist
mv /usr/src/asterisk /usr/src/asterisk_old
# delete if movement failed
rm -fr /usr/src/asterisk
# clean old modules just in case
rm -fr /usr/lib/asterisk/modules/*
# create new
ln -s /usr/src/asterisk-"$ASTERISK_VER" /usr/src/asterisk



procedure_2()
{
# dirty hack to prevent error from missing file
cd /usr/include/linux
touch compiler.h


# h323 libs install

download_packet pwlib-v1_10_0-src-tar.gz;
extract_gz pwlib-v1_10_0-src-tar.gz

# PWLIB
cd /usr/src/pwlib_v1_10_0/

_centos_version    #centos 6 have problems with pwlib compilation because of ssl. A patch is needed
if [ "$centos_version" -gt "5" ]; then
    patch -p0 < /usr/src/mor/patches/asterisk/pwlib-1.10.10-openssl-1.patch
fi

./configure
make
make install
make opt

PWLIBDIR=/usr/src/pwlib_v1_10_0
export PWLIBDIR

# OpenH323
download_packet openh323-v1_18_0-src-tar.gz
extract_gz openh323-v1_18_0-src-tar.gz
cd /usr/src/openh323_v1_18_0/
./configure
make
make opt
make install

OPENH323DIR=/usr/src/openh323_v1_18_0
export OPENH323DIR


echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig


# end of procedure2 - disabling h323/pwlib install
}

PWLIBDIR=/usr/src/pwlib_v1_10_0
export PWLIBDIR
OPENH323DIR=/usr/src/openh323_v1_18_0
export OPENH323DIR

# make menuconfig config to install mysql realtime and other stuff
/bin/cp -r /usr/src/mor/sh_scripts/asterisk/menuselect.make* /usr/src/asterisk

# asterisk install
cd /usr/src/asterisk/channels/h323
make
make opt
cd /usr/src/asterisk
./configure
make
make install

/bin/cp -fr /usr/src/mor/asterisk-conf/ast_1.8/*.conf /etc/asterisk


cd /usr/src/mor/sh_scripts/asterisk/
./codecs_install_ast18.sh


#ivr script
/bin/cp -fr /usr/src/mor/sh_scripts/asterisk/scripts/mor_ast_generate_ivr.c /usr/src/mor/scripts/
cd /usr/src/mor/scripts
./install.sh


exit 1;



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

