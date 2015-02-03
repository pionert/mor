#! /bin/bash

touch /dev/shm/quality_lock
ps aux | grep "quality\|rails" | grep -v grep | awk '{print $2}' | xargs kill

