#!/bin/sh


tarname=`date +%H%M%S%N`
cd /var/log/mor/calllog/
tar -cvf /var/log/mor/calllog/$tarname.tar.gz mor_*.log --remove-files
