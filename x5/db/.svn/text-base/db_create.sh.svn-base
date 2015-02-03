#! /bin/sh

. /usr/src/mor/x5/framework/bash_functions.sh

function db_create(){

  report "Starting fresh DB import" 3

  /usr/bin/mysql -h localhost -u root --password=kolmisoft < /usr/src/mor/x5/db/init.sql
  /usr/bin/mysql -h localhost -u mor --password=mor mor < /usr/src/mor/x5/db/mor.sql
  /usr/src/mor/x5/db/db_update.sh STABLE

  report "New DB created" 0
}

if [ "$1" == "NEW" ]
then
  db_create
else
  get_answer "Are you sure you really want new DB?" "n"
  if [ "$answer" == "y" ]; then
    db_create
  else
    report "New DB not created" 2
  fi
fi
