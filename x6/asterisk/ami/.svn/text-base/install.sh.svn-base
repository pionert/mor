#!/bin/sh

. /usr/src/mor/x6/framework/bash_functions.sh

report "AMI scripts install started" 3

cd /usr/src/mor/x6/asterisk/ami
rm -fr mor_retrieve_peers &> /dev/null
gcc -Wall -g -I/usr/include/mysql mor_retrieve_peers.c -o mor_retrieve_peers -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp mor_retrieve_peers /usr/local/mor/

report "AMI scripts install completed" 0
