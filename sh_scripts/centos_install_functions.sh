#! /bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================



#==============================================
app_mor_install()
{
   if [ $LOCAL_INSTALL == 1 ]; then
      cp /usr/src/other/app_mor.so /usr/lib/asterisk/modules/
   fi
}
