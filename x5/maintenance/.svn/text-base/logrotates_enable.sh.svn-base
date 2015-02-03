#! /bin/sh

. /usr/src/mor/x5/framework/bash_functions.sh

add_critical_logrotates_if_not_present

add_logrotate_if_not_present "/var/log/mor/ami_debug.log" "mor_ami_debug"
add_logrotate_if_not_present "/var/log/mor/record_file.log" "record_file"
add_logrotate_if_not_present "/var/log/mor/blacklist.log" "mor_blacklist"
