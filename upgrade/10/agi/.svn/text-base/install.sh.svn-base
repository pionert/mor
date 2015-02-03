#!/bin/sh

rm mor_callback
gcc -I/usr/include/mysql mor_callback.c -o mor_callback -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib64/mysql
cp -fr /usr/src/mor/upgrade/10/agi/mor_callback /var/lib/asterisk/agi-bin
