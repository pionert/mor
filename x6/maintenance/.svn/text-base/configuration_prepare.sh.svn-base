#!/bin/bash

# Author gilbertas matusevicius

. /usr/src/mor/x6/framework/bash_functions.sh
. /usr/src/mor/x6/framework/settings.sh

# import db settings from /etc/asterisk/mor.conf
import_db_settings() {
    
    # TODO: FIX ME FOR X6 
    
    local config_from="/etc/asterisk/mor.conf"
    local config_to="/etc/mor/system.conf"
    
    #Jei skriptas kvieciamas is x6/install.sh,  /etc/asterisk/mor.conf dar nebus sukurtas 
    #ir nieko importuoti nereikia, nes sviezia sistema.
    
    if [ ! -f $config_from ]; then
        exit 1;
    fi
   
    DB_HOST=`awk -F";" '{print $1}' $config_from | grep -iA 5 "global]" | sed 's/ //g' | grep hostname | awk -F"=" '{print $2}'`;
    DB_NAME=`awk -F";" '{print $1}' $config_from | grep -iA 5 "global]" | sed 's/ //g' | grep dbname | awk  -F"=" '{print $2}'`;
    DB_USERNAME=`awk -F";" '{print $1}' $config_from | grep -iA 5 "global]" | sed 's/ //g' | grep user | awk  -F"=" '{print $2}'`;
    DB_PASSWORD=`awk -F";" '{print $1}' $config_from | grep -iA 5 "global]" | sed 's/ //g' | grep password | awk  -F"=" '{print $2}'`;
    DB_PORT=`awk -F";" '{print $1}' $config_from | grep -iA 5 "global]" | sed 's/ //g' | grep port | awk  -F"=" '{print $2}'`;
    
    if [ $DB_HOST != "localhost" ]; then
        replace_line $config_to "dbhost = localhost" "dbhost = $DB_HOST";
    fi
    
    if [ $DB_NAME != "mor" ]; then
        replace_line $config_to "dbname = mor" "dbname = $DB_NAME";
    fi
    
    if [ $DB_USERNAME != "mor" ]; then
        replace_line $config_to "dbuser = mor" "dbuser = $DB_USERNAME";
    fi
    
    if [ $DB_PASSWORD != "mor" ]; then
        replace_line $config_to "dbsecret = mor" "dbsecret = $DB_PASSWORD";
    fi
    
    if [ $DB_PORT != "3306" ]; then
        replace_line $config_to "dbport = 3306" "dbport = $DB_PORT";
    fi
       
}


important_component_settings() {

   # TODO: FIX ME FOR X6

   # This function is invoked during x4 --> x6 upgrade
   # In X6 components configuration is stored in /etc/mor/system.conf
   # In X4 components configuration is stored in /etc/mor/{asterisk,gui,db}.conf files
   # So this function updates X6 components configuration files from X4 compoenents configuration files 
   
    if [ ! -f "/etc/asterisk/mor.conf" ]; then
        exit 1;
    fi

    local config="/etc/mor/system.conf"
   
   
    #import GUI setting
       
    if [ -f /etc/mor/gui.conf ] && [ $(awk -F"#" '{print $1}' /etc/mor/gui.conf | grep "GUI_PRESENT" | wc -l) == "1" ]; then
        GUI_PRESENT_OLD=$(awk -F"#" '{print $1}' /etc/mor/gui.conf | grep GUI_PRESENT | awk -F"=" '{print $2}')
        replace_line $config "GUI_PRESENT" "GUI_PRESENT=$GUI_PRESENT_OLD"
    fi
   
   
    #import asterisk setting

    if [ -f /etc/mor/asterisk.conf ] && [ $(awk -F"#" '{print $1}' /etc/mor/asterisk.conf | grep "ASTERISK_PRESENT" | wc -l) == "1" ]; then
        ASTERISK_PRESENT_OLD=$(awk -F"#" '{print $1}' /etc/mor/asterisk.conf | grep ASTERISK_PRESENT | awk -F"=" '{print $2}')
        replace_line $config "ASTERISK_PRESENT" "ASTERISK_PRESENT=$ASTERISK_PRESENT_OLD"
    fi
   
   
    #import DB setting
    
    if [ -f /etc/mor/db.conf ] && [ $(awk -F"#" '{print $1}' /etc/mor/db.conf | grep "DB_PRESENT" | wc -l) == "1" ]; then
        DB_PRESENT_OLD=$(awk -F"#" '{print $1}' /etc/mor/db.conf | grep DB_PRESENT | awk -F"=" '{print $2}')
        replace_line $config "DB_PRESENT" "DB_PRESENT=$DB_PRESENT_OLD"
    fi

 
   
   #import DB replication related settings

    if [ -f /etc/mor/db.conf ] && [ $(awk -F"#" '{print $1}' /etc/mor/db.conf | grep BINLOG | wc -l) == 1 ]; then
        BINLOG_SETTING_OLD=$(awk -F"#" '{print \$1}' /etc/mor/db.conf | grep "BINLOG=1" | wc -l)
        replace_line $config "BINLOG" "BINLOG=$BINLOG_OLD_SETTING"
        
    fi
   
    if [ -f /etc/mor/db.conf ] && [ $(awk -F"#" '{print $1}' /etc/mor/db.conf | grep "REPLICATION_M\|REPLICATION_S" | wc -l) == "2" ]; then
        REPLICATION_M_OLD=$(awk -F"#" '{print $1}' /etc/mor/db.conf | grep REPLICATION_M | awk -F"=" '{print $2}')
        REPLICATION_S_OLD=$(awk -F"#" '{print $1}' /etc/mor/db.conf | grep REPLICATION_S | awk -F"=" '{print $2}')
        replace_line $config "REPLICATION_M" "REPLICATION_M=$REPLICATION_M_OLD"
        replace_line $config "REPLICATION_S" "REPLICATION_S=$REPLICATION_S_OLD"
    fi


  
}   





if [ -f /etc/mor/system.conf ]; then

  report "System file already present" 3

else

  mkdir -p /etc/mor
  cp -fr /usr/src/mor/x6/system.conf /etc/mor/system.conf

  report "System file created" 0
  
  # Import settings db settings from /etc/asterisk/mor.conf
  # and component settings from /etc/mor/{gui, db, asterisk}.conf
  # import needed only on first x4->x6 update.sh, if we doing fresh x6/install.sh
  # There is nothing to import.
  
  import_db_settings
  important_component_settings

fi
