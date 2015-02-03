#!/bin/bash


. /usr/src/mor/x6/framework/framework.conf
. $SCRIPTS_DIR/framework/mor_install_functions.sh
. $SCRIPTS_DIR/framework/bash_functions.sh



if [ -f "/usr/lib/asterisk/modules/chan_zap.so" ]; then
    report "Sorry, this Asterisk upgrade script does not support Zaptel upgrade..." 1
    exit 1;
fi

if [ -f "/usr/lib/asterisk/modules/chan_dahdi.so" ]; then
    report "Sorry, this Asterisk upgrade script does not support DAHDI upgrade..." 1
    exit 1;
fi


asterisk_rpms   # exit if asterisk RPMs detected. Reinstall is needed. Function is located at bash_functions.sh

# without sync asterisk will fail to compile
$SCRIPTS_DIR/maintenance/time_sync.sh


# used for script testing to remove parts of logic
procedure_1()
{
    echo "Testing"
} # --- START FROM HERE ---
#exit 1  # --- END HERE ---


yum -y install smartmontools wireshark tar mysql-devel gcc gcc-c++ ncurses-devel bison openssl openssl-devel gnutls gnutls-devel zlib-devel ghostscript make subversion wget sox chkconfig vixie-cron which logrotate postfix lynx gzip bc libxml2-devel flex patch autoconf automake libtool libtiff-devel


$SCRIPTS_DIR/asterisk/srtp_install.sh
$SCRIPTS_DIR/asterisk/spandsp_install.sh


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
    patch -p0 < $SCRIPTS_DIR/asterisk/patch/pwlib-1.10.10-openssl-1.patch
fi

./configure
make -j $CORE_COUNT
make install
make opt

report "PWLIB installed" 0


PWLIBDIR=/usr/src/pwlib_v1_10_0
export PWLIBDIR

# OpenH323
download_packet openh323-v1_18_0-src-tar.gz
extract_gz openh323-v1_18_0-src-tar.gz
cd /usr/src/openh323_v1_18_0/
./configure
make -j $CORE_COUNT
make opt
make install

report "OPENH323 installed" 0


OPENH323DIR=/usr/src/openh323_v1_18_0
export OPENH323DIR


echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig



PWLIBDIR=/usr/src/pwlib_v1_10_0
export PWLIBDIR
OPENH323DIR=/usr/src/openh323_v1_18_0
export OPENH323DIR

# make menuconfig config to install mysql realtime and other stuff
/bin/cp -fr $SCRIPTS_DIR/asterisk/menuselect.make* /usr/src/asterisk

# asterisk install
cd /usr/src/asterisk/channels/h323
make -j $CORE_COUNT
make opt
report "Asterisk H323 installed" 0


cd /usr/src/asterisk
./configure
make -j $CORE_COUNT
make install
make samples


/bin/cp -fr $SCRIPTS_DIR/asterisk/conf/*.conf /etc/asterisk


#proper init script
/bin/cp -fr $SCRIPTS_DIR/asterisk/asterisk_init /etc/init.d/asterisk
chmod 777 /etc/init.d/asterisk
chkconfig --level 345 asterisk on;

#/etc/init.d/asterisk restart


$SCRIPTS_DIR/asterisk/codecs_install.sh

# AGI
cp -r /usr/src/mor/x6/asterisk/agi/mor.conf /var/lib/asterisk/agi-bin/
cd /usr/src/mor/x6/asterisk/agi
./install.sh

# Auto-dialer
ln -s /home/mor/public/ad_sounds /var/lib/asterisk/sounds/mor/ad
chmod 777 /var/lib/asterisk/sounds/mor/ad
chmod 777 /var/lib/asterisk/sounds/mor/
chmod 777 /var/lib/asterisk/sounds/
chmod 777 /var/lib/asterisk/
chmod 777 /var/lib/
chmod 777 /var/

# faxes
cd /var/spool/asterisk
mkdir -p faxes
chmod 777 faxes
chmod 777 outgoing
cd ..
chmod 777 asterisk
cd ..
chmod 777 spool
cd ..
chmod 777 var
ln -s /var/spool/asterisk/faxes/ /home/mor/public/fax2email

# IVR Voices
/usr/src/mor/x6/asterisk/sounds_install.sh

# queues
/usr/src/mor/x6/asterisk/queues_install.sh

# AMI
cd /usr/src/mor/x6/asterisk/ami
./install.sh

# recordings
if [ ! -d /var/spool/asterisk/monitor ] || [ ! -h /home/mor/public/recordings ]; then
    mkdir -p /var/spool/asterisk/monitor
    chmod 777 /var/spool/asterisk/monitor
    ln -s /var/spool/asterisk/monitor /home/mor/public/recordings
    cp -u /usr/src/mor/scripts/mor_wav2mp3 /bin/
fi

# -------
asterisk_current_version #getting current asterisk version
STATUS="$?"
if [ "$STATUS" == "1" ]; then
    report "!!!!!!!!!! Problems detected with Asterisk after upgrade!!!!!" 1
else
    if [ "$ASTERISK_VER" == "$ASTERISK_VERSION" ]; then
        report "Asterisk $ASTERISK_VERSION installed" 0
        #echo -e  "\n\n\nAsterisk $ASTERISK_VER installed with Addons $ADDONS_VER \n\n"
        #echo -e ">>>>> Do not forget to recompile app_mor.so AND compile it to support new Asterisk version! <<<<<<<<\n\nPress ENTER to finish"
        #read
    else
        report "Asterisk upgrade FAILED. Asterisk should have $ASTERISK_VER version, now it has $ASTERISK_VERSION version!" 1
    fi
fi
