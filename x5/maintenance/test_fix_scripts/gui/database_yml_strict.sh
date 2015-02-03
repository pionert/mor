#! /bin/bash


. /usr/src/mor/x5/framework/bash_functions.sh
. /usr/src/mor/x5/framework/mor_install_functions.sh

insert_line_after_pattern "production:" "  strict: false" "/home/mor/config/database.yml"
