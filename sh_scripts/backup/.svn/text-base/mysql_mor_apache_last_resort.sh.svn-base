#! /bin/bash
   #======= includes ===========
      cd /usr/local/mor
      . install_configs.sh
      . mor_install_functions.sh
   #============================
#=================== MAIN ======================
   echo "Do you want to continue (y)?";
   read a;

         echo "Restoring to previous state database..."
      if [ -r "$_mor_backup_dir"/restore/db_dump.sql ];  then   
            mysql -h "$HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" mor < "$_BACKUP_FOLDER"/restore/db_dump.sql;   
            backups_error_output mysql_last_resort_backup
         else 
            echo db_dump not found;
            backups_error_output db_dump_not_found
      fi
      #------------------------------ 
         which_os;   
         apache_stop;
         echo "Restoring to previous state Apache..."
         if [ "$OS" == "DEBIAN" ]; then        
            apache_stop
            cp -R "$_BACKUP_FOLDER"/restore/apache2_back /etc/apache2 
               backups_error_output cp when_moving_"$_BACKUP_FOLDER"/restore/apache2_back_to_/etc/apache2             
            else if [ "$OS" == "CENTOS" ]; then 
               cp -R "$_BACKUP_FOLDER"/restore/httpd_back /etc/httpd; 
                 backups_error_output cp when_moving_"$_BACKUP_FOLDER"/restore/httpd_back_to_/etc/httpd; 
            fi;              	 
         fi;

         echo "Restoring to previous state /home/mor..."
         cp -R "$_BACKUP_FOLDER"/restore/mor_back /home/mor
            backups_error_output cp when_moving_"$_BACKUP_FOLDER"/restore/mor_back_to_/home/mor
         
         apache_start

      echo Done;
else echo Other button pressed, assuming "No"; exit 1; fi
