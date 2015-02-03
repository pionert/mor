#! /bin/sh

#========= includes =========
cd /usr/src/mor
. "$(pwd)"/sh_scripts/mor_install_functions.sh
. "$(pwd)"/sh_scripts/install_configs.sh
. /usr/src/mor/test/framework/bash_functions.sh
#============================

SPANDSP="20120415"

download_packet spandsp-$SPANDSP.tar.gz
extract_gz spandsp-$SPANDSP.tar.gz

#uninstall old spandsp
cd /usr/src/spandsp-0.0.4
make uninstall

#install new

cd /usr/src/spandsp-0.0.6
./configure  --prefix=/usr
make
make install
