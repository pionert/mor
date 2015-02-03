#!/bin/sh

rm ../mor_ad_cron
#gcc -I/usr/include/mysql mor_ad_cron.c -lmysqlclient -lsocket -lnsl -lm -lz
gcc -I/usr/include/mysql mor_ad_cron.c -o ../mor_ad_cron -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql
