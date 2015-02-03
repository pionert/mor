#! /bin/bash
#======includes==========
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==========================

unique_id()
{
   _id_uniq=`cat /etc/passwd | grep $1`;

    if [ -z $_id_uniq ]; then 
	   return 0;
    else 
   	return 1        
    fi
}

alter_etc_passwd()
{
    if [ "$OS" == "DEBIAN" ];  then     
      echo "/etc/passwd ok";
    else
      if [ ! -r /etc/passwd_backup_by_mor ]; then
	      cp /etc/passwd /etc/passwd_backup_by_mor
	      #id=`cat /etc/passwd | grep apache | grep -o "[0-9][0-9]" | grep -m 1 "[0-9][0-9]"` 
	      #apache:x:"$id":"$id":Apache:/var/www:/bin/bash
         cat /etc/passwd | sed '/\/var\/www:\/sbin\/nologin/d' >> /tmp/mor_passwd && mv /tmp/mor_passwd /etc/passwd
      
         id=1000;
	      unique_id $id

	      while [ $? == 1 ] ; do   #generating random number, not mentioned in /etc/passwd
          	    id=$(($id+1))
          	    unique_id $id;
	      done
         
	      echo 'apache:x:'$id':'$id':Apache:/var/www:/bin/bash' >> /etc/passwd        
      fi
            
   fi
}

#-------------------------------------------------
apache_user_setup()
{
   alter_etc_passwd;    #giving shell access for apache user in CentOS     
   mkdir -p /var/www/.ssh/ && > /var/www/.ssh/known_hosts

    if [ "$OS" == "DEBIAN" ];  then 
         chown -R www-data: /var/www/.ssh
    else
         chown -R apache: /var/www/.ssh
    fi;
}


#================   main  =======================================

    mkdir -p /usr/local/mor/
    cp -fr /usr/src/mor/sh_scripts/backup/* /usr/local/mor/
   
    which_os
    apache_user_setup
    mkdir -p /usr/local/mor/backups

    if [ "$OS" == "DEBIAN" ];  then
      chown -R www-data: /usr/local/mor/backups
    else
      chown -R apache: /usr/local/mor/backups
    fi;
 
#=======================================================

