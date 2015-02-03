#! /bin/bash

touch /dev/shm/quality_lock
ps aux | grep "quality\|rails" | grep -v grep | awk '{print $2}' | xargs kill
killall ruby
svn update /usr/src
rm -rf /dev/shm/quality_lock

