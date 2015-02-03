#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013


. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
#--------MAIN -------------
#==== Addons=====

read_mor_gui_settings
if [ "$GUI_PRESENT" == "0" ]; then
    exit 0;
fi

# checking if MOR X4 is installed
mor_gui_current_version
mor_version_mapper "$MOR_VERSION" 
if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "140" ]; then
    /usr/local/mor/mor_ruby /usr/src/mor/upgrade/x4/migrate_add.rb
        
    cp /home/mor/config/environment.rb "/usr/local/mor/backups/GUI/env_rb_$mor_time"

    _mor_time
    temp=`mktemp`    
    grep -v "SKP_Active\|C2C_Active\|AD_sounds_path\|AD_Active\|CC_Active\|RS_Active\|RSPRO_Active\|SMS_Active\|REC_Active\|PG_Active\|MA_Active\|CS_Active\|CC_Single_Login\|PROVB_Active\|AST_18\|WP_Active\|CALLB_Active" /home/mor/config/environment.rb > $temp
    mv $temp /home/mor/config/environment.rb
    chmod 744 /home/mor/config/environment.rb
    
    service httpd restart
fi

