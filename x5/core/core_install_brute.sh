#!/bin/bash

# DON'T USE IT

svn co http://svn.kolmisoft.com/mor/core/branches/x5 /usr/src/mor_core
cd /usr/src/mor_core
make install

cp -fr /usr/src/mor/x5/core/mor.conf /etc/asterisk

asterisk -vvrx "module load app_mor.so"
