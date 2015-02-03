#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#====end of Includes===========================

if [ $LOCAL_INSTALL == 0  ]; then
   if [ -r /etc/redhat-release ]; then
       yum -y install ntp vixie-cron
   else
       apt-get -y install ntpdate
   fi;
fi;
		#====== pending delete
				#touch /tmp/ntpdate.sh
				#echo "#!/bin/sh" > /tmp/ntpdate.sh
				#echo "" >> /tmp/ntpdate.sh
				#echo "ntpdate pool.ntp.org >> /var/log/ntpdate.log" >> /tmp/ntpdate.sh
				#chmod 777 /tmp/ntpdate.sh
				#mv /tmp/ntpdate.sh /etc/cron.hourly
		#========== pending delete 2 =============================================
				#touch $HOME/.crontab_tmp        #making temporary crontab_file
				#crontab -u $USER -l >> $HOME/.crontab_tmp #moving old crons


				#NTPD=`cat $HOME/.crontab_tmp | grep -i "ntpdate"`;
				#if [ "$NTPD" == "" ]; then 

				#	 touch $HOME/.crontab  #making new crontab_file
				#	 cat  $HOME/.crontab_tmp >> $HOME/.crontab #moving old crons
				#	 echo "0 * * * * /usr/sbin/ntpdate pool.ntp.org >> /var/log/ntpdate.log" >> $HOME/.crontab
				#	 echo  >> $HOME/.crontab
				#	 crontab $HOME/.crontab


				#	 rm -rf $HOME/.crontab  # cleaning the mess

				#fi


				#rm -rf $HOME/.crontab_tmp  # cleaning the mess
		#========================================================================

#		crontab_add "ntpdate.log" "0 * * * * /usr/sbin/ntpdate pool.ntp.org >> /var/log/ntpdate.log" "ntpdate_installed"
