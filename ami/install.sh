#!/bin/sh


rm mor_retrieve_peers
gcc -Wall -g -I/usr/include/mysql mor_retrieve_peers.c -o mor_retrieve_peers -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp /usr/src/mor/ami/mor_retrieve_peers /usr/local/mor/

