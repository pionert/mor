#!/bin/sh

#rm ./mor_ad_agi.so
#rm ./mor_ad_agi.o
#rm ./mor_ad_agi
#rm ../mor_ad_cron
#gcc -I/usr/include/mysql mor_ad_cron.c -lmysqlclient -lsocket -lnsl -lm -lz
gcc -I/usr/include/mysql mor_ad_agi.c -o mor_ad_agi -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql

cp mor_ad_agi /var/lib/asterisk/agi-bin