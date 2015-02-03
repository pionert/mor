#! /bin/sh

. /usr/src/mor/x5/framework/framework.conf
. $SCRIPTS_DIR/framework/mor_install_functions.sh
. $SCRIPTS_DIR/framework/bash_functions.sh

download_packet srtp-1.4.2.tgz
extract_gz srtp-1.4.2.tgz

cd /usr/src/srtp
./configure CFLAGS=-fPIC --prefix=/usr
make -j $CORE_COUNT
make install

report "SRTP installed" 0
