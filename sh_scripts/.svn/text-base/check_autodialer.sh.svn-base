#!/bin/bash

function autodialer_test() {
	echo ===========================================================================
	echo Testing Auto-Dialer addon
	echo ===========================================================================
	grep -i -n '#cron.*' /etc/syslog.conf | wc -l | while read a   #how many matches?
	do
		if [ "$a" -eq 1 ]; then #how many matches?		
			cp /etc/syslog.conf /etc/syslog.conf.backup #backing up the file
			if [ -r /etc/syslog.conf.backup ] 
			then
				echo "/etc/syslog.conf successfully backuped";
				if [ -x /bin/sed ]
				then 	
					sed -e 's/#cron.*/cron.*/g'   /etc/syslog.conf > $HOME/.mor_tmp 				
				else 
					echo apt-get install sed;
					sed -e 's/#cron.*/cron.*/g'   /etc/syslog.conf > $HOME/.mor_tmp 				
				fi
				
				mv -f $HOME/.mor_tmp /etc/syslog.conf
				rm -rf $HOME/.mor_tmp
			else 
				echo "backing up /etc/syslog.conf failed"
			fi
			#---------------------------------------------------------------------
			echo Restarting sysklogd
				/etc/init.d/sysklogd restart
			# prevention from mess if script is being used multiple times
			rm -rf $HOME/.crontab_tmp  # cleaning the mess 
			rm -rf $HOME/.crontab  # cleaning the mess
			#------------------------------------------------------------
			touch $HOME/.crontab_tmp	#making temporary crontab_file
			crontab -u $USER -l >> $HOME/.crontab_tmp #moving old crons

			touch $HOME/.crontab  #making new crontab_file
			cat  $HOME/.crontab_tmp >> $HOME/.crontab #moving old crons
			echo "*/5 * * * * /home/mor_ad/mor_ad_cron >> /home/mor_ad/mor_ad_cron.log" >> $HOME/.crontab
			echo  >> $HOME/.crontab 
			crontab $HOME/.crontab

			rm -rf $HOME/.crontab_tmp  # cleaning the mess
			rm -rf $HOME/.crontab  # cleaning the mess
		else #----------------------------------------------------
		     #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
			echo "Enabling crontab logs automaticaly - Failed";
			echo "Enable crontab logs by hand: ";
			echo "1: /etc/syslog.conf uncomment cron.*";

			/etc/init.d/sysklogd restart
			export EDITOR='mcedit';
			echo "2: execute crontab -e";
			echo "3: at the file's end add */5 * * * * /home/mor_ad/mor_ad_cron >> /home/mor_ad/mor_ad_cron.log";
			echo "4: make sure you pressed ENTER after this line, without this it won't work";
			echo "Press a button";
			read;
			crontab -e;
		fi						
	done; # end of do loop
		echo "if you see something like this:";
		echo "2007-12-07 00:01:53 - Start of MOR Auto-Dialer Cron script.";
		echo "DB config. Host: localhost, DB name: mor, user: mor, psw: mor, port: 3306.";
		echo "Successfully connected to database.";
		echo "No campaigns found active this time: 00:01:53";
		echo "Total campaigns retrieved: 0";
		echo "======================= after this line===============================";
		tail  /home/mor_ad/mor_ad_cron.log;
		echo "Then everything is OK, the test was passed";
}


autodialer_test
