#! /bin/sh
# Authors: Kenneth Aarum Mostrøm
# About:  This script install VoiBill
# Company: VoiCall 
# Website: http://www.voicallglobal.com
#
# ====== How to use this script? =====
#
# If you run this script without any parameters like this:
# ./install.sh
#
# it will install MOR version defined in variable DEFAULT_VERSION.
#
# You can install a desired MOR version by specifying it's number. Supported paramters (version numbers) are:
#
# $1 - 8, 9, 10, 11, 12.126, 18, extend
#
VERSION_PASSED_BY_PARAMETERS="$1";
#==================================================
export PATH="/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin" 
export LANG="en_US.UTF-8"
DEFAULT_VERSION="12.126";
if [ "$VERSION_PASSED_BY_PARAMETERS" == "" ]; then VERSION_PASSED_BY_PARAMETERS="$DEFAULT_VERSION"; fi

export VERSION_PASSED_BY_PARAMETERS
mkdir -p /var/log/mor/
echo  "$VERSION_PASSED_BY_PARAMETERS" > /var/log/mor/version


#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
    . /usr/src/mor/sh_scripts/logrotate.sh
    . /usr/src/mor/sh_scripts/centos_install_functions.sh
    . /usr/src/mor/test/framework/bash_functions.sh
#====end of Includes===========================
   /usr/src/mor/sh_scripts/kolmisoft_logo_txt.sh
    processor_type
    which_os

   _centos_version
/usr/src/mor/test/scripts/information/hdd_smart_status.sh FIRST_INSTALL
/usr/src/mor/test/scripts/various/ntpdate.sh FIRST_INSTALL
/usr/src/mor/test/scripts/information/hdd_space_in_root.sh FIRST_INSTALL
/usr/src/mor/test/scripts/information/check_ram.sh FIRST_INSTALL

asterisk_rpms   # exit if asterisk RPMs detected. Reinstall is needed. Function is located at bash_functions.sh

/usr/src/mor/test/scripts/various/other_products.sh FIRST_INSTALL

mor_version_mapper "$VERSION_PASSED_BY_PARAMETERS"
bashrc_config #vitally important for centos
chmod 777 /tmp

cp_mv_alias_remove

#--- remembering install time
mkdir -p /usr/local/mor
_mor_time
echo "$mor_time" > /usr/local/mor/install_date


are_we_inside_screen
if [ "$?" == "1" ]; then
    report "You have to run this script from 'screen' program. To do so - just run command 'screen' and launch the script again as usual"   1
    exit 1
fi


detect_vm   # check if this machine is virtual?
if [ "$VM_DETECTED" == "0" ]; then
    #======= Torture test questions ======
    report "It is very important that during peak of your calls the server would be reliable. To ensure this after installation we will launch a server torture test which will put a lot of load on your server to test RAM and CPU if they are working correctly during heavy load" 3
    echo "How much time would like to torture the server? (Valid answer is 2+ hours. Press Enter for default: 2 hours)"
    
    TORTURE_HOURS="1"
    while read a; do
        if [ "$a" == "" ]; then # enter pressed
            REPORT_TORTURE_EMAIL="support@voicallglobal.com"
            break
        fi
        
        # checking if provided input is number
        if [ `echo "$a" | grep "[a-z,A-Z,\!,\?]" | wc -l` != "0" ]; then
          report "Please use only numbers" 3
          continue  
        fi
        
        # check if provided value is greater than 48
        if [ "$a" -gt "48" ]; then
            report "It is not reasonable to test more than 48 hours, please enter a lower value" 3
            continue
        fi
    
        # check if provided value is lees than 2 hours
        if [ "$a" -lt "2" ]; then
            report "It is not reasonable to test less than 2 hours, please enter a higher value" 3
            continue
        fi
    
        TORTURE_HOURS="$a"    # if we made it till here - the value is OK
        
        default_interface_ip
        
        check_if_ip_is_registered_in_kolmisoft_support_system $DEFAULT_IP
        if [ "$?" == "0" ]; then
            REPORT_TORTURE_EMAIL="support@voicallglobal.com  kenneth@voicallglobal.com"
        else
            
            while [ "$REPORT_TORTURE_EMAIL" == "" ]; do
                echo -e "Please enter valid Email where you would like to get torture results/n/n"
                read REPORT_TORTURE_EMAIL
                if [ `echo $REPORT_TORTURE_EMAIL | grep "@" | wc -l` == "0" ]; then
                    REPORT_TORTURE_EMAIL=""
                fi
            done
        fi
        
        break   # exiting the loop
    done
else
  if [ "$VM_TYPE" == "LXC" ]; then
    report "Sorry but your virtualization technology LXC is not supported" 1
    exit 1
  fi
fi
#======== system update=========
    yum -y update
	
#======== DB backup ============
        mor_db_backup "before_upgrade_to_0.6_"
#===============================

echo -e "\n================Updating the system==================\n"
if [ "$OS" == "DEBIAN" ];
   then
      apt-get install tar debian-archive-keyring
      apt-get update;
      wait_user;
      apt-get -y install libncurses5-dev anacron libssl-dev zlib1g-dev make ssh php5-cli gcc g++ libmysqlclient15-dev mysql-client-5.0 psmisc subversion sox logrotate
   else if [ "$OS" == "CENTOS" ];
   then
      #disable SELinux!!!
      /bin/cp -r /usr/src/mor/centos/selinux/config /etc/selinux/
      #echo 0 >/selinux/enforce
	setenforce 0

      #============

	#yum -y remove iptables
	#iptables -F
	#/etc/init.d/iptables save

      if [ $LOCAL_INSTALL == 0 ]; then
         yum -y install tar mc mysql-devel gcc gcc-c++ ncurses-devel bison openssl openssl-devel gnutls-devel zlib-devel ghostscript make subversion wget sox chkconfig vixie-cron which logrotate postfix lynx gzip bc curl-devel
      fi


      #============
   fi
   wait_user;
fi;

#==============================================

if [ $INSTALL_DB == 1 ]; then
   if [ "$OS" == "DEBIAN" ];
      then apt-get -y install mysql-server
      else  if [ "$OS" == "CENTOS" -a $LOCAL_INSTALL == 0 ];
            then
               yum -y install mysql mysql-server
               #/etc/init.d/mysqld start
               mysql_start
            fi
   fi;

    if [ "$OS" == "CENTOS" ]; then
        chkconfig --level 345 mysqld on
        /usr/src/mor/sh_scripts/mysql_5_5.sh
        /usr/src/mor/sh_scripts/db_one_file_per_table.sh "RESTART"   # Adds option to /etc/my.cnf in order separate tables would be stored on separate files (better performance on big databases)
    fi;

   wait_user
fi

#==============================================
if [ $INSTALL_GUI == 1 ]; then
   if [ "$OS" == "DEBIAN" ];
      then apt-get -y install apache2 apache2-threaded-dev php5-gd php5-mysql libfcgi-ruby1.8 libmysql-ruby libapache2-mod-php5 phpmyadmin libapache2-mod-fcgid libopenssl-ruby;
      else
         if [ "$OS" == "CENTOS" ];
               then
                  if [ $LOCAL_INSTALL == 0 ]; then
                     yum -y install httpd httpd-devel php php-gd php-mysql anacron php-mcrypt php-mbstring apr-util-devel
                  fi

		         chmod 555 /var/log/httpd
	            chkconfig --level 345 httpd on

                  echo "Installing phpmyadmin";
                  download_packet phpMyAdmin-2.11.5.1-english.tar.gz
                  extract_gz phpMyAdmin-2.11.5.1-english.tar.gz
                               #tar zxvf phpMyAdmin-2.11.5.1-english.tar.gz
                  mv phpMyAdmin-2.11.5.1-english phpmyadmin
                  mv /usr/src/phpmyadmin /var/www/html/phpmyadmin
                  mv /var/www/html/phpmyadmin/config.sample.inc.php /var/www/html/phpmyadmin/config.inc.php

                  cd /usr/src/mor/sh_scripts/
		    ./pmapg.sh


         fi;
   fi;
   wait_user
fi

#==============================================
echo -e "\n\n===============Installing Ruby + Rails============\n\n"

if [ $INSTALL_GUI == 1 -a $CENTOS4 == 1 ];
   then  #centos 4
      cd /etc/yum.repos.d/
      wget http://dev.centos.org/centos/4/CentOS-Testing.repo
      yum -y --enablerepo=c4-testing install ruby ruby-docs ri ruby-libs ruby-mode rdoc ruby-devel
   else
      if [ $INSTALL_GUI == 1 -a "$OS" == "CENTOS" -a $LOCAL_INSTALL == 0 ]; then
         yum -y install ruby
         yum -y install ruby-irb
         yum -y install ruby-docs
         yum -y install ruby-libs ruby-mode rdoc
         yum -y install ri
         yum -y install ruby-devel
      fi
fi

#============================================
if [ $INSTALL_GUI == 1 ]; then
   if [ "$OS" == "DEBIAN" ];
   then
      apt-get -y install ruby rdoc1.8 irb libyaml-ruby libzlib-ruby ruby1.8-dev

      download_packet rubygems-1.3.5.tgz;
      extract_gz rubygems-1.3.5.tgz
      cd rubygems-1.3.5
      ruby setup.rb

      gem install rails -v=1.2.6 --no-rdoc --no-ri
      gem install pdf-writer --include-dependencies --no-rdoc --no-ri
      gem install builder --include-dependencies --no-rdoc --no-ri
      gem install rails -v=1.2.6 --no-rdoc --no-ri	#sometimes it does not get installed first time
      # gem install pdf-wrapper -y --no-rdoc --no-ri
      wait_user
	  /usr/src/mor/sh_scripts/debian_fcgid.sh

   else if [ "$OS" == "CENTOS" ];
   then


      if [ "$centos_version" == "6" ]; then
          processor_type
          if [ "$_64BIT" == "1" ]; then
              download_packet fcgi-2.4.0-5.el5.kb.x86_64.rpm
              download_packet fcgi-devel-2.4.0-5.el5.kb.x86_64.rpm
              rpm -Uvh fcgi-2.4.0-5.el5.kb.x86_64.rpm fcgi-devel-2.4.0-5.el5.kb.x86_64.rpm
          else
              download_packet fcgi-2.4.0-5.el5.kb.i386.rpm
              download_packet fcgi-devel-2.4.0-5.el5.kb.i386.rpm
              rpm -Uvh fcgi-2.4.0-5.el5.kb.i386.rpm fcgi-devel-2.4.0-5.el5.kb.i386.rpm
          fi
      fi

      download_packet rubygems-1.3.5.tgz
      extract_gz rubygems-1.3.5.tgz
      cd rubygems-1.3.5
      ruby setup.rb
      /usr/src/mor/test/scripts/gui/ruby_gems_check_and_repair.sh first
      /usr/src/mor/sh_scripts/centos_fcgid.sh
   fi
fi;
fi;
wait_user


#==============   LAME    =====================================================

# we need lame on GUI also to convert uploaded files
if [ "$LOCAL_INSTALL" == "0" ]; then		#if installing from the internet
        echo -e "\nInstalling Lame\n-----------------------------------------------\n";
        download_packet lame-3.97b2.tar.gz
        extract_gz lame-3.97b2.tar.gz

        cd lame-3.97
        ./configure
        make
        make install
        wait_user;
else
        rpm -Uvh /usr/src/lame-3.97b2-1.i386.rpm
fi

#==========================================================
if [ $INSTALL_ZAPTEL == 1 ]
then
   echo -e "\nInstalling Zaptel\n----------------------------------------------\n"
   if [ "$OS" == "CENTOS" -a $LOCAL_INSTALL == 0 ]; then
      yum -y install gcc gcc-c++ kernel-devel bison openssl-devel libtermcap-devel ncurses-devel doxygen
      yum -y install kernel-smp-devel
   fi;

   download_packet zaptel-"$ZAPTEL_VER".tar.gz
   extract_gz zaptel-"$ZAPTEL_VER".tar.gz

   ln -s /usr/src/zaptel-"$ZAPTEL_VER" /usr/src/zaptel
   cd /usr/src/zaptel
   make clean
   ./configure
   make
   make install
   make config

   if [ "$OS" == "CENTOS" ]; then
      #edit /etc/zaptel
      chkconfig zaptel on
      service zaptel start
   fi;

   ztcfg -vvv
   wait_user
fi




#========================   H323   ==============================================
if [ $INSTALL_H323 == 1 ]; then echo -e "\nH323\n-----------------------------------------------\n";
   if [ "$OS" == "DEBIAN" ]; then apt-get -y install flex bison
      elif [ "$OS" == "CENTOS" -a $LOCAL_INSTALL == 0 ]; then yum -y install flex bison;
   fi;


	if [ "$LOCAL_INSTALL" == "0" ]; then		#if installing from the internet
        wait_user
        #dirty hack to prevent error from missing file
        cd /usr/include/linux
        touch compiler.h

        #PWLIB
        #asterisk_stop;

        download_packet pwlib-v1_10_0-src-tar.gz;
        extract_gz pwlib-v1_10_0-src-tar.gz # tar zxvf pwlib-v1_10_0-src-tar.gz

        cd pwlib_v1_10_0/
        _centos_version    #centos 6 have problems with pwlib compilation because of ssl. A patch is needed
        if [ "$centos_version" -gt "5" ]; then
            yum -y install patch
            patch -p0 < /usr/src/mor/patches/asterisk/pwlib-1.10.10-openssl-1.patch
        fi
        ./configure
        make
        make install
        make opt
        PWLIBDIR=/usr/src/pwlib_v1_10_0
        export PWLIBDIR

        wait_user

        #OpenH323
        download_packet openh323-v1_18_0-src-tar.gz
        extract_gz openh323-v1_18_0-src-tar.gz

        cd openh323_v1_18_0/
        ./configure
        make
        make opt
        make install
        OPENH323DIR=/usr/src/openh323_v1_18_0/
        export OPENH323DIR

        echo "/usr/local/lib" >> /etc/ld.so.conf
        ldconfig

      #or similar way
      #cp /usr/local/lib/* /usr/lib
   	wait_user
	else  #if installing from install cd
		rpm -Uvh /usr/src/openh323-v1_18_0-1.i386.rpm /usr/src/pwlib-v1_10_0-1.i386.rpm
	fi


fi

#===================  Asterisk   ==================================
if [ $INSTALL_APP == 1 ]; then echo -e "\nInstalling Asterisk\n-----------------------------------------------\n"
	if [ "$LOCAL_INSTALL" == "0" ]; then		#if installing from the internet
 		download_packet asterisk-"$ASTERISK_VER".tar.gz
   		download_packet libpri-"$LIBPRI_VER".tar.gz
		download_packet asterisk-addons-"$ADDONS_VER".tar.gz
		wait_user
		extract_gz asterisk-"$ASTERISK_VER".tar.gz
		extract_gz libpri-"$LIBPRI_VER".tar.gz
		extract_gz asterisk-addons-"$ADDONS_VER".tar.gz
		#move away old links/dirs if they exist
		mv /usr/src/asterisk /usr/src/asterisk_old
		mv /usr/src/asterisk-addons /usr/src/asterisk-addons_old
    		#create new
		ln -s /usr/src/asterisk-"$ASTERISK_VER" /usr/src/asterisk
		ln -s /usr/src/asterisk-addons-"$ADDONS_VER" /usr/src/asterisk-addons

		cd libpri-"$LIBPRI_VER"
		make
		make install
		if [ $INSTALL_H323 == 1 ]; then
			cd /usr/src/asterisk/channels/h323/
			make
			make opt
		fi
   		wait_user
		 # remove it to fix previous unsuccesful installation
		 rm -fr /etc/asterisk
		cd /usr/src/asterisk
		./configure
		make
		make install
		make samples
		#make config
		#install correct asterisk start script
		#cp -fr /usr/src/mor/mor_app/apps/app_mor.so /usr/lib/asterisk/modules
		if [ "$OS" == "DEBIAN" ];
		   then
			   cp -fr /usr/src/mor/sh_scripts/asterisk_debian /etc/init.d/asterisk
			   chmod 777 /etc/init.d/asterisk
		      update-rc.d asterisk defaults
		      cp /usr/src/mor/asterisk-addons/1.4/* /usr/src/asterisk-addons
		   else
		      if [ "$OS" == "CENTOS" ];
		         then
			        cp -fr /usr/src/mor/sh_scripts/asterisk_redhat /etc/init.d/asterisk
			        chmod 777 /etc/init.d/asterisk
		           chkconfig --level 345 asterisk on;
		           /bin/cp -r /usr/src/mor/asterisk-addons/1.4/* /usr/src/asterisk-addons
		      fi
		fi;
		cd /usr/src/asterisk-addons
		./configure
		make
		make install
		wait_user
	else		#if installing from the mor install cd
		rpm -Uvh /usr/src/asterisk-1.4.18.1-1.i386.rpm /usr/src/asterisk-addons-1.4.7-1.i386.rpm /usr/src/libpri-1.4.4-1.i386.rpm
	fi

fi

#=================    Installing MOR    ============================

if [ $INSTALL_APP == 1 ]; then

    echo -e "\nInstalling MOR\n-----------------------------------------------\n"

   #install agi
   cd /usr/src/mor/agi
   ./install.sh
   #cp -fr /usr/src/mor/agi/mor-recordings.php /var/lib/asterisk/agi-bin
   cp -fr /usr/src/mor/asterisk-conf/* /etc/asterisk/

   echo ';MOR Configuration' >> /etc/asterisk/extensions.conf
   echo '#include extensions_mor.conf' >> /etc/asterisk/extensions.conf

   cp -u /usr/src/mor/scripts/mor_wav2mp3 /bin/

   #------- install sounds
   download_packet mor_sounds.tgz;
   extract_gz mor_sounds.tgz        #tar xzvf mor_sounds.tgz

   cp -ur /usr/src/sounds/* /var/lib/asterisk/sounds

   #  cp -ur /usr/src/mor/sounds/* /var/lib/asterisk/sounds

   #----app----------------------------------
   cp -u /usr/src/mor/mor_app/conf/mor.conf /etc/asterisk
   #cd /usr/src/mor/mor_app
   #make install

   asterisk_stop;

   #/etc/init.d/asterisk start       # starting nicely

   wait_user
fi
#=======================  DB  ==============================================

if [ "$INSTALL_DB" == "1" ]
then
    echo -e "\nImporting DB\n-----------------------------------------------\n"
   mysql_restart;
   /usr/src/mor/db/mor_create_db.sh
   wait_user
fi;

#==========================  GUI  ==========================================

if [ $INSTALL_GUI == 1 ]; then

    echo -e "\nInstalling GUI\n-----------------------------------------------\n"

   cd /home
   rails mor
   #cp -ur /usr/src/mor/gui/* /home/mor/
   unalias cp  &> /dev/null  #removing cp alias if such exist
   cp -rf  /usr/src/mor/gui/* /home/mor/

   #update GUI from SVN
   if [ $LOCAL_INSTALL == 1 ]; then

        if [ $UPGRADE_TO_8 == 0 ]; then
    	    cp -R -f $TRUNK_DIR_0_6/* /home/mor/
    	fi


      elif [ $LOCAL_INSTALL == 0 ]; then
          rm -rf /tmp/mor
          svn co http://svn.kolmisoft.com/mor/branches/0.6 /tmp/mor
          cp -fr /tmp/mor /home/
          rm -rf /tmp/mor
   fi

    mkdir -p /home/mor/public/ad_sounds

   chmod 777 /home/mor/public/images/logo
   chmod 777 /home/mor/public/images/logo/*
   chmod 777 /home/mor/public/ad_sounds

   cd /home/mor/log
   touch fastcgi.crash.log
   chmod 777 *
   cd ..
   chmod 777 log

#    touch /var/www/html/index.html
   wait_user
#   echo -e "\nLast configuration \n-----------------------------------------------\n"


   if [ "$OS" == "DEBIAN" ]; then ln -s /home/mor/public /var/www/billing
      else if [ "$OS" == "CENTOS" ]; then ln -s /home/mor/public /var/www/html/billing; fi
   fi;

    if [ "$OS" == "DEBIAN" ]; then
       a2enmod rewrite
       apache_hard_stop;
       cp -fr /usr/src/mor/apache2-conf/default /etc/apache2/sites-available
    fi

   rm -rf /home/mor/public/index.html;

   cd /home/mor/tmp
   chmod 777 *
   touch /var/www/index.html
   #logo
   chmod 777 /home/mor/public/images/logo
   cd /home/mor/public/images/logo
   chmod 777 *
   #c2c
   chmod 777 /home/mor/public/c2c_greetings
   cd /home/mor/public/c2c_greetings
   chmod 777 *
   ln -s /home/mor/public/c2c_greetings /var/lib/asterisk/sounds/mor/c2c_greetings


   cd /var/spool/asterisk/monitor
   touch index.html

   ln -s /var/spool/asterisk/monitor /home/mor/public/recordings

   #debug log
   ln -s /home/mor/log/production.log /home/mor/public/debug/production.log
   ln -s /tmp/mor_debug.txt /home/mor/public/debug/mor_debug.txt
   if [ "$OS" == "DEBIAN" ]; then ln -s /var/log/apache2/error_log /home/mor/public/debug/apache_error.log; fi

fi

#===================  Fax2Email  ============================
if [ $INSTALL_APP == 1 ]; then echo -e "\nFax2Email\n-----------------------------------------------\n"
   if [ "$OS" == "DEBIAN" ];  then apt-get -y install g++ libtiff4 libtiff4-dev patch autoconf automake libtiff-tools
   elif [ "$OS" == "CENTOS" -a $LOCAL_INSTALL == 0 ];
            then yum -y install g++ libtiff libtiff-devel patch autoconf automake;
   fi;


	if [ "$LOCAL_INSTALL" == "0" ]; then		#if installing from the internet
		download_packet spandsp-"$SPANDSP_VER".tgz;
		extract_gz spandsp-"$SPANDSP_VER".tgz

		cd /usr/src/spandsp-0.0.4
		./configure
		make
		make install
	else
		rpm -Uvh /usr/src/spandsp-0.0.4-1.i386.rpm
	fi

   wait_user

    if [ $INSTALL_H323 == 0 ]; then
       echo "/usr/local/lib" >> /etc/ld.so.conf
       ldconfig
    fi

   cd /var/spool/asterisk
   mkdir -p faxes
   chmod 777 faxes
   chmod 777 outgoing
   cd ..
   chmod 777 asterisk
   cd ..
   chmod 777 spool
   cd ..
   chmod 777 var

   ln -s /var/spool/asterisk/faxes/ /home/mor/public/fax2email

   #nv_faxdetect rxfax txfax
   cd /usr/src/mor/fax2email/additional_apps
   make clean
   make
   make install

   #fax2email agi
   cd /usr/src/mor/fax2email/agi
   ./install.sh
   cp -r /usr/src/mor/fax2email/agi/mor.conf /var/lib/asterisk/agi-bin/

   asterisk_stop;

   cp -r /usr/src/mor/fax2email/fax_test.tif /var/spool/asterisk/faxes/

   #Callback AGI

   cd /usr/src/mor/callback/agi
   ./install.sh

   wait_user
fi


#========================  Autodialer  ========================================
if [ $INSTALL_AUTO_DIALER == 1 ]; then echo -e "\nAUTO DIALER\n -----------------------------------------------\n"
   cp -r /usr/src/mor/mor_ad /home/
   cd /home/mor_ad/app/
   ./install.sh
   cd /home/mor_ad/agi/
   ./install.sh

   ln -s /home/mor/public/ad_sounds /var/lib/asterisk/sounds/mor/ad
   chmod 777 /var/lib/asterisk/sounds/mor/ad
   chmod 777 /var/lib/asterisk/sounds/mor/
   chmod 777 /var/lib/asterisk/sounds/
   chmod 777 /var/lib/asterisk/
   chmod 777 /var/lib/
   chmod 777 /var/

   wait_user
fi

#========================  Codecs  ========================================
   echo -e "\nCodecs\n -----------------------------------------------\n"

    asterisk_stop;
    /etc/init.d/asterisk start


  /usr/src/mor/sh_scripts/codecs_install.sh
 
  /usr/src/mor/sh_scripts/redhat_centos_after_install_function.sh
      
#=============================================================================
   apache_hard_restart; # restarting apache(hard)

   /usr/src/mor/sh_scripts/ntpdate.sh #time sync script

   /usr/src/mor/sh_scripts/sendEmail_install.sh  #sendEmail script install

   cp -fr /usr/src/mor/sh_scripts/gui_upgrade.sh /home/mor
   cp -fr /usr/src/mor/sh_scripts/gui_upgrade_light.sh /home/mor

#===========Copying global mor bash functions and configs=====================
   cp /usr/src/mor/sh_scripts/mor_install_functions.sh /usr/local/mor/
   cp /usr/src/mor/sh_scripts/install_configs.sh /usr/local/mor/

    chmod 777 /tmp
    chmod 777 /tmp/mor_debug.txt


#=======Copying configs===============
    backup_folder
    copy_functions_configs
#=====================================
    upgrade_to_0_7;

    #try_to_update_gui; #if internet is available - try to update, removed because duplicate with upgrade_to_0_7

    if [ $UPGRADE_TO_8 == 1 ]; then
        update_mor_version_file 8
        upgrade_to_8;
        upgrade_gui_from_svn;
    fi

    #app_mor_install;
    install_app_mor;

    echo "export EDITOR='mcedit'" >> /root/.bashrc

    ln -s /usr/src/mor /root/mor_dir

    chkconfig --add postfix
    /etc/init.d/postfix start

    ldconfig


   if [ $LOCAL_INSTALL == 1 ]; then
		cat /usr/src/mor/sh_scripts/install_configs.sh | sed 's/LOCAL_INSTALL=1/LOCAL_INSTALL=0/g' > /tmp/install_configs.sh
		cp -fr /tmp/install_configs.sh /usr/src/mor/sh_scripts/install_configs.sh
		rm -fr /tmp/install_configs.sh
   fi


    # permissions
    touch /tmp/mor_debug.txt
    chmod 777 /tmp/mor_debug.txt
    chmod 777 /home/mor/public/images/logo/

    # elunia stats
    cd /usr/src/mor/sh_scripts
    ./install_elunia_stats.sh

    # fail2ban
    cd /usr/src/mor/sh_scripts
    ./fail2ban_install.sh

    /usr/src/mor/test/scripts/various/yum-updatesd.sh

#======cleaning===============================================================
   cleaning_script
#=============================================================================
   

    if [ "$centos_version" == "6" ]; then
        if [ "$_64BIT" == "1" ]; then
            yum -y install zlib.i686 zlib-devel.i686
        fi
        yum -y install openssh-clients
    fi

   /usr/src/mor/test/scripts/asterisk/mnp_cfgs.sh "FIRST_INSTALL"

#---- Upgrade ------
# check function "mor_version_mapper" for details
if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "90" ]; then
    /usr/src/mor/upgrade/9/fix.sh
fi
if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "100" ]; then
    /usr/src/mor/upgrade/10/fix.sh
fi
if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "110" ]; then
    /usr/src/mor/upgrade/11/fix.sh
fi
if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "120" ]; then
    /usr/src/mor/upgrade/12.126/fix.sh
fi
if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "123" ]; then
    /usr/src/mor/upgrade/12/fix.sh
fi



if [ "$INSTALL_DB" == "1" ]; then
  /usr/bin/mysql -h localhost -u mor --password=mor mor < /usr/src/mor/db/fresh_install_sqls.sql # These SQL required only for new customers. To enable/disable options which can be already configured by existing customers their way.
fi

#-------------------
echo -e "\n\n===============================================================\nCongratulations! You have installed MOR $VERSION_PASSED_BY_PARAMETERS\n\n"

echo Go to your webrowser and enter: http://`ifconfig | awk '/inet addr:/ {print $2}' | awk '{split ($0,a,":"); print a[2]}' | awk '{split ($0,a,"127."); print a[1]}'`/billing/
echo "-----------------------------------------------";


if [ "$VM_DETECTED" == "0" ]; then
    # Server performance testing
    /usr/src/mor/test/stress.sh $TORTURE_HOURS $REPORT_TORTURE_EMAIL
else
    report "Virtual Machine detected. Will not run torture tests" 3
fi

