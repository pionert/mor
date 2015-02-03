#! /bin/sh

ASTERISK_VER="1.6.0.6" 

yum -y install  gcc gcc-c++ ncurses-devel bison  openssl openssl-devel  gnutls-devel zlib-devel wget make

cd /usr/src
wget http://downloads.digium.com/pub/asterisk/releases/asterisk-"$ASTERISK_VER".tar.gz 

tar xzvf asterisk-"$ASTERISK_VER".tar.gz 

ln -s /usr/src/asterisk-"$ASTERISK_VER" /usr/src/asterisk 

cd /usr/src/asterisk
./configure
make
make install
make samples
make config 

