#!/bin/sh

/usr/bin/mysql -h localhost -u root -p < /usr/src/mor/db/mnp_init.sql 

touch /usr/local/mor/mor_mnp.conf

echo "host = localhost
db = mor_mnp
user = mor
secret = mor
port = 3306
server_id = 1
show_sql = 0
debug = 1
" > /usr/local/mor/mor_mnp.conf

cd /usr/src/mor/agi
./install.sh
