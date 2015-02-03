#!/bin/sh
#==== Includes=====================================
   cd /usr/src/mor
   . "$(pwd)"/sh_scripts/install_configs.sh
#====end of Includes===========================

#============ SOX install =====================================
SOX=`which sox`
if [ "$SOX" == "" -a $LOCAL_INSTALL == 0 ]; then 

    echo -e "\nSOX present: no"

    if [ -r /etc/redhat-release ]; then
	   yum -y install sox
    else
	   apt-get -y install sox
    fi;    
else
    echo -e "\nSOX present: yes"    
fi
#==============EXPECT INSTALL===================================

EXPECT=`which expect`;
if [ "$EXPECT" == "" -a $LOCAL_INSTALL == 0 ]; then 
    echo -e "\nexpect present: no"

    if [ -r /etc/redhat-release ]; 
      then yum -y install expect	
      else apt-get -y install expect	
    fi; 
   else
    echo -e "\nexpect present: yes";    
fi


chmod 777 /tmp
chmod 777 /tmp/mor_debug.txt



# ==========  Time sync ==========================
/usr/src/mor/sh_scripts/ntpdate.sh
#====== Backup system install ====================
/usr/src/mor/sh_scripts/backup_restore_install.sh
#====== phpSysInfo install ====================
/usr/src/mor/sh_scripts/phpsysinfo_install.sh
#====== phpMyAdmin install/fix ====================
/usr/src/mor/sh_scripts/pmapg.sh

mkdir -p /var/log/mor
