#! /bin/sh

#========= includes =========
cd /usr/src/mor
. "$(pwd)"/sh_scripts/mor_install_functions.sh
. "$(pwd)"/sh_scripts/install_configs.sh
. /usr/src/mor/test/framework/bash_functions.sh
#============================


download_packet srtp-1.4.2.tgz
extract_gz srtp-1.4.2.tgz

cd /usr/src/srtp
./configure CFLAGS=-fPIC --prefix=/usr
make
make install
