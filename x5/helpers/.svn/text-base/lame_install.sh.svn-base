#!/bin/bash

. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/mor_install_functions.sh


_lame=`which lame  2> /dev/null`
if [ $? == 0 ];   then
    report "Lame already installed" 0
    exit 0;
fi

report "Starting Lame install" 3

download_packet lame-3.97b2.tar.gz
extract_gz lame-3.97b2.tar.gz

cd lame-3.97
./configure
make -j $CORE_COUNT
make install

_lame=`which lame  2> /dev/null`
if [ $? == 0 ];   then
    report "Lame installed" 0
    exit 0;
else
    report "Lame NOT installed" 1
    exit 1;
fi

