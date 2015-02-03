#! /bin/sh

. /usr/src/mor/x6/framework/framework.conf
. $SCRIPTS_DIR/framework/mor_install_functions.sh
. $SCRIPTS_DIR/framework/bash_functions.sh

SPANDSP="20120415"

download_packet spandsp-$SPANDSP.tar.gz
extract_gz spandsp-$SPANDSP.tar.gz

#uninstall old spandsp
cd /usr/src/spandsp-0.0.4
make uninstall

#install new

yum -y install libtiff-devel

cd /usr/src/spandsp-0.0.6
./configure  --prefix=/usr
make -j $CORE_COUNT
make install

report "SpanDSP installed" 0
