#! /bin/bash 
#=============================
error_output()  #this function is used for error loging
{
   if [ ! $? = 0 ]; 
   then 
      if [ -n $2 ]; 
         then echo "There was an error in $1 function; $2" >> $_LOG
         else echo "There was an error in $1 function" >> $_LOG     
      fi        
      echo 1;
      exit 1;
   fi;  
}

#=============================

expect -c 'spawn ssh '$5'@'$4' -p'$7' "/etc/init.d/asterisk start" ; expect password ; send "'$6'\n" ; interact'
         error_output asterisk_restore executing_asterisk_start_cmd_via_ssh_failed_in_"$4"_server

