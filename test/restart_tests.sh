#!/bin/bash

killall -9 mor_test_run.sh
killall -9 tickets_test_run2.sh #crm
killall -9 ruby
killall -9 firefox
/etc/init.d/mysqld restart # For "Subsystem locked" problem in order the system would be able to recover
/etc/init.d/httpd restart
rm -fr /tmp/.mor_test_is_running
ps aux | grep mor | grep -v restart | awk  '{print $2}' | xargs kill -9
