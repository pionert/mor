#! /bin/bash

/usr/src/mor/x6/mysql/mysql_5_5.sh
/usr/src/mor/x6/mysql/db_one_file_per_table.sh "RESTART"

chkconfig --level 345 mysqld on

# not good, must change later
mysqladmin -u root password kolmisoft
