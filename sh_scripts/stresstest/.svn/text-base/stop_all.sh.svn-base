#!/bin/sh

cd /var/spool/asterisk/outgoing/
rm -f *

killall -9 safe_asterisk
killall -9 asterisk

/etc/init.d/asterisk start
