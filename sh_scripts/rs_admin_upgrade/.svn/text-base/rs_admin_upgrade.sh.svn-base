#! /bin/bash

exec >  >(tee -a rs_admin_upgrade.log)
exec 2> >(tee -a rs_admin_upgrade.log >&2)


#==== Includes=====================================
   cd /usr/src/mor
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
    . /usr/src/mor/test/framework/bash_functions.sh
#==================================================
NO_SCREEN="$1"  # Option to be tolerant on running without screen

if [ "$NO_SCREEN" != "NO_SCREEN" ]; then    # require to be running from screen from now on
    are_we_inside_screen
    if [ "$?" == "1" ]; then
      report "You have to run this script from 'screen' program. To do so - just run command 'screen' and launch the script again as usual"   1
      exit 1
    fi
fi


echo `date`

mysql_connect_data

/usr/src/mor/test/scripts/mysql/mysql_grants.sh

FILE="/usr/src/mor/sh_scripts/rs_admin_upgrade/db_changes.sql"
exec < $FILE
while read LINE
do
  char=${LINE:0:2}
  if [ ${LINE:0:1} == "#" ]; then
    echo -e "  \e[93m$LINE\e[97m"
  else
    echo -e "  \e[32mEXECUTING SQL:\e[97m $LINE"
    mysql_sql "$LINE"
  fi

done

echo `date`
