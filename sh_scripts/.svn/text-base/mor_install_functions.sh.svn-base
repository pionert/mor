#! /bin/bash
# last_update 2008 12 09
#== USER INTERFACE FUNCTIONS======================
wait_user() {   if [ $WITH_STOPS == 1 ]; then echo -e "\n\n Press enter to continue; "; read; echo -e "\n\n"; fi;    }

wait_user2() {   echo -e "\nPress enter to continue\n\n"; read; echo -e "\n\n"; }

_done() {  echo -e "\ndone.\n"; }

press_enter_to_exit()
{
   if [ $WITH_STOPS == 1 ]; then
      echo "Press ENTER to exit";
      read
   fi
}
#================================================
processor_type()
{
 _UNAME=`uname -a`;
 _IS_64_BIT=`echo "$_UNAME"  | grep x86_64`
 if [ -n "$_IS_64_BIT" ];
   then _64BIT=1;
   else _64BIT=0;
 fi;
}
#================================================
which_os()
{
   if [ -r /etc/debian_version ];
      then  OS="DEBIAN";
      else
         if [ -r /etc/redhat-release ]; then
           OS="CENTOS";
           processor_type;

            #If centos 4 is not detected - problem exists in grep
            _IS_CENTOS_4=`cat /etc/redhat-release | grep "Centos 4*"`

            if [ -n "$_IS_CENTOS_4" ];
               then CENTOS4=1;
               else CENTOS4=0;
            fi;
         fi;
   fi;
}
#================================================
cleaning_script()
{
   echo -e "\n\nCleaning\n-----------------------------------------------\n";
   if [ "$OS" == "DEBIAN" ];  then apt-get clean
   else	if [ "$OS" == "CENTOS" ]; then yum clean all; fi;
   fi;
}
#================================================
apache_stop()
{
   if [ -r /etc/debian_version ];
      then  /etc/init.d/apache2 stop;
      else
         if [ -r /etc/redhat-release ];
         then /etc/init.d/httpd stop; fi;
   fi;
}
#================================================
apache_hard_stop()
{
   if [ -r /etc/debian_version ];
      then  /etc/init.d/apache2 stop;
            killall -9 apache2;
      else
         if [ -r /etc/redhat-release ];
            then  /etc/init.d/httpd stop;
                   killall -9 httpd;
         fi;
   fi;
}
#=====================
apache_start()
{
   if [ -r /etc/debian_version ];
      then  /etc/init.d/apache2 start;
      else
         if [ -r /etc/redhat-release ];
         then /etc/init.d/httpd start; fi;
   fi;
}
#======================
apache_restart()
{
   if [ -r /etc/debian_version ];
      then  /etc/init.d/apache2 restart;
      else
         if [ -r /etc/redhat-release ];
         then /etc/init.d/httpd restart; fi;
   fi;
}
#======================
apache_hard_restart()
{
   which_os
   if [ "$OS" == "DEBIAN" ];
      then
	      /etc/init.d/apache2 stop
	      sleep 3
	      killall -9 apache2
	      /etc/init.d/apache2 start
      elif [ "$OS" == "CENTOS" ]; then
	      /etc/init.d/httpd stop
	      sleep 3
	      killall -9 httpd
	      /etc/init.d/httpd start
      fi
}
#=====================
mysql_start()
{
   which_os;
   if [ "$OS" == "DEBIAN" ];
      then /etc/init.d/mysql start --user=mysql;
      elif [ "$OS" == "CENTOS" ]; then /etc/init.d/mysqld start;
   fi;
}
#===========================================
mysql_restart()
{
   which_os;
   if [ "$OS" == "DEBIAN" ];
      then /etc/init.d/mysql restart --user=mysql;
      elif [ "$OS" == "CENTOS" ]; then /etc/init.d/mysqld restart;
   fi;
}
#===========================================
mysql_connect_data()
{      #set -e
      if [ -r /home/mor/config/database.yml ];
         then
            cat /home/mor/config/database.yml | grep -iA 5 production: | grep -iA 4 database: > /tmp/mor_db.txt
            DATABASE=`cat /tmp/mor_db.txt | grep database | cut -c 13- | sed "s/'\|\"//g"`;
            DB_USERNAME=`cat /tmp/mor_db.txt | grep username | cut -c 13- | sed "s/'\|\"//g"` ;
            DB_PASSWORD=`cat /tmp/mor_db.txt | grep password | cut -c 13- | sed "s/'\|\"//g"`;
            HOST=`cat /tmp/mor_db.txt | grep host | cut -c 9- | sed "s/'\|\"//g"`;

            
            if [ "$DB_USERNAME" -a "$DATABASE" -a "$DB_PASSWORD" -a "$HOST" != "" ];
               then echo "Username, database, password and host were found";
               else  echo "There was an error, please enter the following mysql info by hand:";
                     echo "Database name:"; read DATABASE;
                     echo "User name:"; read DB_USERNAME;
                     echo "Password:"; read DB_PASSWORD;
                     echo "Host:"; read HOST;
            fi
         else
					echo "Can't read /home/mor/config/database.yml";
				  	return 1;
      fi
     rm -rf /tmp/mor_db.txt

    DB_HOST="$HOST"
    DB_NAME="$DATABASE"

     return 0
}
#===========================================
asterisk_stop()
{  /etc/init.d/asterisk stop
   asterisk -vvvvrx "stop now"
   killall -9 safe_asterisk
   killall -9 asterisk
}
#===========================================
asterisk_reload()
{
   asterisk -vvvvvrx 'reload'
}
#===========================================
download_packet()
{
   cd $DEFAULT_DOWNLOAD_DIR;
   if [ $LOCAL_INSTALL == 0 ]; then
      if [ -r $1 ];
         then echo "$1 is already downloaded";
         else wget "$KOLMISOFT_URL"/packets/$1
            if [ $? != 0 ]; then
               data=`date`
               echo -n $data >> $DOWNLOAD_LOG;
               echo -e " $1 failed to download\n#==================" >> $DOWNLOAD_LOG;
            fi
      fi;
   fi;
}
#========================================
alias_update()
{
	cat /tmp/.bashrc2 | grep "$1" &> /dev/null
	if [ $? == 1 ]; then echo "$1" >> /tmp/.bashrc2 ; fi

}
#===========================================
cp_mv_alias_remove()
{     which_os;
      if [ "$OS" == "CENTOS" ]; then
         cat $HOME/.bashrc | sed -e '/alias cp/d' > /tmp/.bashrc
         cat /tmp/.bashrc | sed -e '/alias mv/d' > /tmp/.bashrc2
         mv $HOME/.bashrc $HOME/.bashrc_mor_back


			alias_update "alias cgp='/usr/src/mor/sh_scripts/cgp'"
         alias_update "alias nano='nano -w'"
			alias_update "alias showcrash='tail -n 500 /tmp/mor_crash.log'"

			alias_update "alias astbrutal='asterisk_stop() {  /etc/init.d/asterisk stop;    asterisk -vvvvrx \"stop now\";    killall -9 safe_asterisk;    killall -9 asterisk; }'"



         mv /tmp/.bashrc2 $HOME/.bashrc;
      fi
}
#============================================
bashrc_config()
{
   which_os;
   if [ "$OS" == "DEBIAN" ]; then
      alias rm="rm";
      alias mv="mv";
      alias cp="cp";
   fi;
}
#============================================
codecs_uninstall()
{
   rm -rf /usr/lib/asterisk/modules/codec_g723.so
   rm -rf /usr/lib/asterisk/modules/codec_g729.so
}
#============================================
find_and_execute_rb()
{
   find $1 -name "*.rb" | while read a; do ruby "$a"; done;
}
#=============================================
extract_gz()
{  if [ $VERBOSE == 0 ];
      then tar -xzf $1;
      else tar -xzvf $1;
   fi
}
#============================================
mysql_sql()
{
   if [ $VERBOSE == 0 ];
	then /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "$1" 2> /tmp/mor_mysql_tables_outp
			if [ $? != 0 ]; then return 1; fi
      elif [ $VERBOSE == 1 ];
			then /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "$1";
			if [ $? != 0 ]; then return 1; fi
   fi
}
#============================================
sql_include()
{
   if [ $VERBOSE == 0 ]; then /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < "$1" 2> /tmp/mor_mysql_tables_outp
      elif [ $VERBOSE == 1 ]; then /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < "$1";
   fi
}
#============================================
upgrade_to_0_7()
{
   if [ $UPGRADE_TO_0_7 == 1 ]; then
      cd /usr/src/mor/upgrade/0.7
      ./upgrade_to_0.7.sh
      ./fix_0.7.sh
   fi
}
#==============================================
upgrade_to_8()
{
   if [ $UPGRADE_TO_8 == 1 ]; then
      cd /usr/src/mor/upgrade/0.8
      ./fix_0.8.sh
	cd /usr/src/mor/db/0.8/
	./make_clean_mor8_db.sh
   fi
}
#==============================================

run_tests()
{   if [ $RUN_TESTS_AFTER_INSTALL == 1 ]; then
      cd /usr/src/mor
      ./test.sh
   fi;
}
#==============================================
backup_folder()
{
   if [ -d  $_BACKUP_FOLDER ];
      then
         cd $_BACKUP_FOLDER
         mkdir -p guidb asterisk #gali trukti guidb/home
      else
         mkdir -p $_BACKUP_FOLDER
         backup_folder
   fi;
}
#================================================
backups_error_output()  #this function is used for error loging
{
   if [ ! $? = 0 ];
   then
      if [ -n $2 ]; then
            echo -n `date` >> $BACKUP_LOG;
            echo " There was an error in $0 script $LINENO: $1 function; $2" >> $BACKUP_LOG
         else
            echo -n `date` >> $BACKUP_LOG;
            echo "There was an error in $0 script $LINENO: $1 function" >> $BACKUP_LOG
      fi
      echo 1;
      exit 1;
   fi;
}
#================================================
copy_functions_configs()
{
   cp -R /usr/src/mor/sh_scripts/mor_install_functions.sh /usr/local/mor/mor_install_functions.sh
   cp -R /usr/src/mor/sh_scripts/install_configs.sh /usr/local/mor/install_configs.sh
}
#================================================
kolmi_ping()
{  #FIRST ARGUMENT - IP TO CHECK
   ping_cmd=`ping -c 1 $1 | grep "1 received"`;
   if [ -n "$ping_cmd" ]; then
      return 0;
      else return 1;
   fi
}
#=================================================
try_to_update_gui()
{
	if [ $INSTALL_GUI == 1 ]; then
		kolmi_ping $KOLMISOFT_IP
		if [ $? == 0 ]; then
		      cd /usr/src/mor/upgrade/0.7
		      ./gui_upgrade.sh
		fi
	fi
}
#=================================================
replace_line_in_file()
{  #1 arg - file to modify
   #2 arg - what to replace
   #3 arg - replace with
   #4 arg must be 1, if backup is needed
   #exemple: replace_line_in_file /tmp/somefile foo bar 1

   cat $1 | sed 's/'$2'/'$3'/' > /tmp/replace_line$$;

   if [ $4 == 1 ]; then mv $1 $1_back$$; fi

   mv /tmp/replace_line$$ $1
}
#=================================================
mor_database_exists()
{
	which mysql &> /dev/null;
	if [ $? == 1 ]; then MOR_DB=0; return 1; fi

	if [ ! -r "/home/mor/config/database.yml" ]; then MOR_DB=0; return 1; fi

	#checks wheather mor database exists. Sets MOR_DB=1 if exists sets MOR_DB=0 of otherwise.
	mor_db=`mysql_sql "show databases" | grep -w "mor"`;

	if [ "$mor_db" == "mor" ];
		then
			echo "mor db exists"
			MOR_DB=1;
		else
			echo "system is clean"
			MOR_DB=0;
	fi
}
#=================================================
_mor_time()
{
	mor_time=`date +%Y\.%-m\.%-d\-%-k\-%-M\-%-S`;
}
#=================================================
mor_db_backup() #argument 1 - any string you like. You can use it to mark the backup.Examples of such string: "backup_before_upgrade_to_0.6"
{
	if [ -f "/home/mor/config/database.yml" ]; then
		mysql_connect_data
			backups_error_output mysql_connect_data
		mor_database_exists

		if [ $MOR_DB == 1 ]; then
			cd $_BACKUP_FOLDER;
			echo "Backing up the mor db";
			_mor_time

			cd "$_BACKUP_FOLDER"
			mysqldump -h "$HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" --single-transaction --ignore-table=mor.backups mor >  "$_BACKUP_FOLDER"/MOR_db_dump_"$1"_"$mor_time".sql;
			mor_compress 'MOR_db_dump_'$1'_'$mor_time'.sql' 1
		fi
	else echo "NO database config file found, assuming that there is no database";
	fi
}
#=================================================
mor_compress()
{
    if [ ! -f "/bin/tar" ]; then
        yum -y install tar
        if [ ! -f "/bin/tar" ]; then
            echo "Failed to install tar"
            exit 1;
        fi
    fi

	tar -czf $1.tar.gz $1
	if [ "$?" != "0" ]; then
        return 1;
    fi

	if ( test $2 == 1 ); then
		rm -rf $1
	fi
}
#=================================================
exec_and_evaluate()
{
   if [ -z "$1" ]; then echo "Argument not passed for function evaluation"; read a; fi;
   # first argument - test function name
   $1 $2 "$3"; #executing test
   result=$?;
	_log="/tmp/mor_test_log"
   if [ "$result" == "1" ];
		then
		   echo -e "$3\t\t\t\t\t\t[\E[31m FAILED \E[37m]";
		   echo "$1 failed" >> $_log

		elif [ "$result" == "0" ]; then
		   echo -e "$3\t\t\t\t\t\t[\E[32m   OK   \E[37m]";

		elif [ "$result" == "2" ]; then
		   echo -e "$3\t\t\t\t\t\t[\E[37mWARNING!\E[37m]";
   fi
}
#=================================================
crontab_check()
{	#$1 string to check. example: crontab_check "ntpdate_log"
	crontab -l | grep -o "$1" &> /dev/null
	if [ $? == 0 ];	then return 0;
							else return 1;
	fi
}
#===============================================================
report_to_stdout()
{
   if [ -z "$1" ]; then echo "Argument not passed for function evaluation"; read a; fi;
   if [ "$1" == "1" ];
                then
                   echo -e "$2\t\t\t\t\t\t$3[\E[31m FAILED \E[37m]";
                elif [ "$1" == "0" ]; then
                   echo -e "$2\t\t\t\t\t\t$3[\E[32m   OK   \E[37m]";
                elif [ "$1" == "2" ]; then
                   echo -e "$2\t\t\t\t\t\t$3[\E[37mWARNING!\E[37m]";
                elif [ "$1" == "3" ]; then
                   echo -e "$2\t\t\t\t\t$3[\E[33mADDED\E[37m]";
                elif [ "$1" == "4" ]; then
                   echo -e "$2\t\t\t\t\t\t$3[\E[33minstalled\E[37m]";
                elif [ "$1" == "5" ]; then
                   echo -e "$2\t\t\t\t\t\t$3[\E[33mOverwritten\E[37m]";
                elif [ "$1" == "6" ]; then
                   echo -e "$2\t\t\t\t\t\t$3[\E[33mNotice\E[37m]";

   fi
}
#===============================================================
uncomment_cron_if_needed()
{	grep -i -n '#cron.*' /etc/syslog.conf | wc -l | while read a
	do
		if [ "$a" -eq 1 ]; then #how many matches?
			cp /etc/syslog.conf /etc/syslog.conf_mor_backup #backing up the file
			if [ -r "/etc/syslog.conf_mor_backup" ]
			then
				echo "/etc/syslog.conf successfully backuped";
				sed -e 's/#cron.*/cron.*/g'   /etc/syslog.conf > $HOME/.mor_tmp
				mv -f $HOME/.mor_tmp /etc/syslog.conf
				rm -rf $HOME/.mor_tmp
				echo "Restarting syslogd"
				which_os
				if [ "$OS" == "DEBIAN" ];
					then /etc/init.d/sysklogd restart;
					elif [ "$OS" == "CENTOS" ]; then /etc/init.d/syslog restart;
				fi;
			else
				echo "backing up /etc/syslog.conf failed"
				return 1
			fi
		fi
	done
}
#===============================================================
crontab_add()
{
	#argument 1 - string to check in crontab
	#argument 2 - string to add to crontab
	#argument 3 - string to use when printing the results
	#example: crontab_add "mor_ad_cron.log" "*/5 * * * * /home/mor_ad/mor_ad_cron >> /home/mor_ad/mor_ad_cron.log" "Autodialer_installed"

	crontab_check "$1";
		if [ $? == 0 ]; then
			report_to_stdout 0 "$3"
			return 0;
		fi

	uncomment_cron_if_needed

	rm -rf $HOME/.crontab_tmp  # cleaning the mess
	rm -rf $HOME/.crontab  # cleaning the mess

	touch $HOME/.crontab_tmp	#making temporary crontab_file
	crontab -u $USER -l >> $HOME/.crontab_tmp #moving old crons

	touch $HOME/.crontab  #making new crontab_file
	cat  $HOME/.crontab_tmp >> $HOME/.crontab #moving old crons
	echo "$2" >> $HOME/.crontab
	echo  >> $HOME/.crontab
	crontab $HOME/.crontab

	rm -rf $HOME/.crontab_tmp  # cleaning the mess
	rm -rf $HOME/.crontab  # cleaning the mess

	crontab_check "$1";

	if [ $? == 0 ]; then
		report_to_stdout 3 "$3"
		else report_to_stdout 1 "$3"
	fi
}
#=================================================================
insert_line_after_pattern()
{	#special characters need to be escaped like:   \$
	#arg1 - pattern
	#arg2 - what to add
	#arg3 - path to file
	#example: insert_line_after_pattern "\[mysqld\]" "max_allowed_packet=100M" "/etc/my.cnf"

	if [ ! -f "$3" ]; then return 1; fi

	cat "$3" | grep "$2" &> /dev/null

	if [ $? == 0 ]; then
		report_to_stdout 0 "$2 already exist in $3"
	else
		cp $3 $3.mor_backup;
		sed '/'$1'.*$/a\'$2'' "$3" > /tmp/.mor_tmp && cat /tmp/.mor_tmp > "$3" && rm -rf /tmp/.mor_tmp
		#++++++++++++++++++++++++++++
		cat "$3" | grep "$2" &> /dev/null
		if [ $? == 0 ]; then
			report_to_stdout 3 "$2 added successfully to $3"
		else
			report_to_stdout 1 "Adding $2 to $3 failed$4"
		fi
	fi
}
#==================================================================
file_exist()
{  echo -ne "Checking whether $1 exists $2"
   if [ -f "$1" ];    then return 0;
                      else return 1;
   fi
}
#==============================================
dir_exists()
{
   if [ -d "$1" ];  	then return 0;
                     else return 1;
   fi
}
#==============================================
test_if_all_files_dir_exist()
{ #usage: test_if_all_files_dir_exist file_with_paths
	cat $1 | while read a;
				do
					file_exist $a &> /dev/null
					if [ $? == 0 ]; then continue; fi

					dir_exists $a;

					if [ $? == 0 ];
						then continue;
						else return 1;
					fi
				done
}
#===============================================

product_install()
{
	#arg1=path to file with paths to test
	#arg2=product name used in reporting
	#arg3= product install function name, example: pwlib_install

	test_if_all_files_dir_exist "$1"

	if [ $? == 0 ];
		then
			report_to_stdout 0 "$2 installed";
			return 0;
		elif [ $? == 1 ]; then
				$3 #product_install_function_name
				#--------------------
			test_if_all_files_dir_exist "$1"  #testing once more
				#--------------------

			if [ $? == 0 ]; then
				report_to_stdout 4 "$2 installed";
			else
				report_to_stdout 1 "$2 installation failed";
			fi
	fi
}
#==============================================================
mor_admin_pass_crack()
{
	# if arg 1 is passed - the script executes that command or other script (the gui login/pass then will be admin/admin)

	cd /usr/src/mor
   . "$(pwd)"/sh_scripts/install_configs.sh

	if [ -f "/root/mor_gui_admin_pass_hash" ]; then echo -e "\E[31m/root/mor_gui_admin_pass_hash found, please correct your mistakes manually, I won't overwrite user's pass hash backup\E[37m]"; return 1; fi
	mysql_connect_data; &> /dev/null
	if [ $? == 1 ]; then
		echo "Failed to get database data, exiting..";
		return 1;
	fi
	#==================================
	current_pass=`mysql_sql "select password from users where id='0';" | sed -n '2,2 p'`  			#backing up the current user password hash
	echo "$current_pass" >> /root/mor_gui_admin_pass_hash;
		if [ $? != 0 ];
		then
			echo "Failed to get the current admin pass";
			return 1;
		fi
	mysql_sql "update users set password = 'd033e22ae348aeb5660fc2140aec35850c4da997' where id = 0;"	#setting the default pass
		if [ $? != 0 ];
			then 	echo "Failed to set default pass";
				return 1;
		fi

	if [ "$1" != "" ]; then #execute a specific command if needed
			$1
		fi

	wait_user2
	mysql_sql "update users set password = '$current_pass' where id = 0;"	#restoring user's original pass
		if [ $? != 0 ]; then
			echo -e "Failed to restore the original user pass, you can find the original user pass hash in:\n /root/mor_gui_admin_pass_hash"
			return 1;
		fi
	echo "Original user pass was restored"
	echo "Cleaned the mess..";
	rm -rf /root/mor_gui_admin_pass_hash
	return 0
}
#===================================================
check_config_line_and_execute_cmd()
{	#----------------------------
	#function checks file for a specific line and executes a cmd if a line does not exist
	#arg1=path to file
	#arg2=string to check
	#arg3=what to write in report
	#arg4=cmd to execute
	#-----------------------------

cat "$1" | grep "^$2" &> /dev/null
	if [ $? == 1 ]; then
		$4  #executing cmd
		cat "$1" | grep "^$2" &> /dev/null
		if [ $? == 1 ]; 	then report_to_stdout 1 "$3"
								else report_to_stdout 5 "$3"
		fi
	fi

	if [ $? == 0 ]; then
		report_to_stdout 0 "$3"
	fi
}
#==========================================




svn_ping(){
	if [ "$ENABLE_SVN_PING" == "0" ]; then  #if set to 0 in install_configs.sh - svn ping is disabled
		return 0;
	fi


	SVN_ADDRESS="svn.kolmisoft.com";

	wget "http://$SVN_ADDRESS" &> /dev/null;
	if [ "$?" == "0" ]; then return 0;
		else
			echo "=== Failed to ping the svn ===";
		 	return 1;
	fi
}

upgrade_install_scripts(){
	svn_ping;				#pinging the svn server
	if [ "$?" == "0" ];
		then svn co http://svn.kolmisoft.com/mor/install_script/trunk/ /usr/src/mor
		else echo "Failed to upgrade install scripts";
	fi
}
#------------------------------------------
upgrade_gui_from_svn(){
	#parameters: $1 - version for
	#valid versions: 0.6, 0.7, 8 and so on. If you want the latest - don't use any arguments
	#the last upgrade shoud

	rm -rf /tmp/mor
	svn_ping;

	if [ "$?" == "0" ]; #if ping succeeded
		then
			if [ "$VERSION_PASSED_BY_PARAMETERS" == "$1" ]; then
				svn co http://svn.kolmisoft.com/mor/gui/branches/$1 /tmp/mor ;
			elif [ "$VERSION_PASSED_BY_PARAMETERS" == "" ]; then
				svn co http://svn.kolmisoft.com/mor/gui/trunk /tmp/mor ;
				cp -f -r -v /tmp/mor /home/
				rm -rf /tmp/mor
			fi
#		elif [ "$?" == "1" ] && [ "$LOCAL_INSTALL" == "1" ] && [ "$1" == "" ]; then cp -R /usr/src/other/trunk_gui/* /home/mor/;
	fi
}

#========================

install_app_mor(){
	#this functions is used for app_mor.so installation

	if [ "$VERSION_PASSED_BY_PARAMETERS" == "" ]; then VERSION_PASSED_BY_PARAMETERS=`cat /var/log/mor/version`; fi  #version is passed to install.sh script
	if [ "$VERSION_PASSED_BY_PARAMETERS" == "" ]; then VERSION_PASSED_BY_PARAMETERS=8; fi

	processor_type;
	svn_ping;

	#make backup of old app
    if [ -f "/usr/lib/asterisk/modules/app_mor.so" ]; then
	    cp -fr /usr/lib/asterisk/modules/app_mor.so /usr/lib/asterisk/modules/app_mor.so_backup
        echo "app_mor.so backup was made";
    fi

	if [ "$?" == "0" ]; #with internet
	then
		echo "Installing app_mor.so from internet"

		if [ "$_64BIT" == "1" ]; then
			wget "$KOLMISOFT_URL"/packets/core/"$VERSION_PASSED_BY_PARAMETERS"/64/app_mor.so
		elif  [ "$_64BIT" == "0" ]; then
			wget "$KOLMISOFT_URL"/packets/core/"$VERSION_PASSED_BY_PARAMETERS"/32/app_mor.so
		else
			echo "Problem encountered when determining whether the system is 64 bit";
			echo "Problem encountered when determining whether the system is 64 bit" >> "$DOWNLOAD_LOG";
		fi


		mv app_mor.so /usr/lib/asterisk/modules/ #moving app_mor.so to the right place
	else #no internet
		echo "Local installing app_mor.so"
		cp -fr /usr/src/other/app_mor.so /usr/lib/asterisk/modules/ #moving app_mor.so to the right place
	fi

	chmod 755 /usr/lib/asterisk/modules/app_mor.so

	if [ -f "/usr/lib/asterisk/modules/app_mor.so" ];
		then echo "app_mor.so install was successfull";
		else
			echo "app_mor.so install FAILED";
			echo "app_mor.so install FAILED" >> "$MOR_DEBUG";
	fi
	asterisk -vvvvrx 'module unload app_mor.so'
	asterisk -vvvvrx 'module load app_mor.so'
}

#===================================
update_mor_version_file(){

	VERSION_IN_FILE=`cat /var/log/mor/version`

	if [ "$VERSION_PASSED_BY_PARAMETERS" \> "$VERSION_IN_FILE" ]; then
		echo "$VERSION_PASSED_BY_PARAMETERS" > $VERSION_IN_FILE; #updating version file
		return 0;
	fi

	if [ "$VERSION_PASSED_BY_PARAMETERS" == "" ]; then
		if [ "$VERSION_IN_FILE" \< "$1" ]; then
			echo "$1" > $VERSION_IN_FILE;
		fi
	fi
}



