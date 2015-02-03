#!/bin/sh

            #rm ./mor_ad_agi.so
            #rm ./mor_ad_agi.o
            #rm ./mor_ad_agi
            #rm ../mor_ad_cron
            #gcc -I/usr/include/mysql mor_ad_cron.c -lmysqlclient -lsocket -lnsl -lm -lz

rm mor_fax2email

gcc -Wall -g -I/usr/include/mysql mor_fax2email.c -o mor_fax2email -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql

cp -fr mor_fax2email /var/lib/asterisk/agi-bin
