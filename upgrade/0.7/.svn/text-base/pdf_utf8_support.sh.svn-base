#!/bin/sh
#==== Includes=====================================
. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh
#====end of Includes===========================

    processor_type
    which_os 

echo -e "\n======== Ruby Cairo/Pango upgrade ========\n"


echo -e "\n======== PDF UTF8 support ========";


    if [ "$OS" == "CENTOS" ]; then
         if [ $LOCAL_INSTALL == 0 ]; then
	         yum install -y gtk+ glib gdk-pixbuf atk which #gtk2
	         yum install -y ruby-gtk2
	         yum install -y cairo cairo-devel ruby-cairo
	         yum install -y pango pango-devel ruby-pango
         #elif [ $LOCAL_INSTALL == 1 ]; then
            # no need to install, should be installed already
            #rpm -Uvh gtk+-1.2.10-56.el5.i386.rpm libXi-1.0.1-3.1.i386.rpm gdk-pixbuf-0.22.0-25.el5.i386.rpm
         fi


	
	   if [ $_64BIT == 1 ]; then 
	   
	    if [ $LOCAL_INSTALL == 0 ]; then	
	       download_packet cairo-1.6.4-1.fc9.x86_64.rpm
	       download_packet pixman-0.10.0-1.fc9.x86_64.rpm
	       download_packet cairo-devel-1.6.4-1.fc9.x86_64.rpm
	       download_packet pixman-devel-0.10.0-1.fc9.x86_64.rpm
	    fi
					           
	       rpm -ifvh --replacepkgs --replacefiles pixman-0.10.0-1.fc9.x86_64.rpm #1 !Correct installation order is very important
	       rpm -ifvh --replacepkgs --replacefiles pixman-devel-0.10.0-1.fc9.x86_64.rpm #2
	       rpm -ifvh --replacepkgs --replacefiles cairo-1.6.4-1.fc9.x86_64.rpm #3
	       rpm -ifvh --replacepkgs --replacefiles cairo-devel-1.6.4-1.fc9.x86_64.rpm #4 
	   else
	       
	       rpm -e cairo-devel-1.2.4-5.el5.i386 --nodeps
	       rpm -e cairo-1.2.4-5.el5 --nodeps
	    
	        if [ $LOCAL_INSTALL == 0 ]; then       
	    	    
	    	    download_packet pixman-0.10.0-1.fc9.i386.rpm
	    	    download_packet cairo-devel-1.6.4-1.fc9.i386.rpm
	    	    download_packet pixman-devel-0.10.0-1.fc9.i386.rpm
	    	    download_packet cairo-1.6.4-1.fc9.i386.rpm
	    	    					
	    	    rpm --install $DEFAULT_DOWNLOAD_DIR/pixman-0.10.0-1.fc9.i386.rpm
	    	    rpm -ifvh --replacepkgs --replacefiles $DEFAULT_DOWNLOAD_DIR/cairo-1.6.4-1.fc9.i386.rpm
	    	    #rpm --install $DEFAULT_DOWNLOAD_DIR/cairo-devel-1.6.4-1.fc9.i386.rpm
	    	    rpm --install $DEFAULT_DOWNLOAD_DIR/pixman-devel-0.10.0-1.fc9.i386.rpm
		    rpm --install $DEFAULT_DOWNLOAD_DIR/cairo-devel-1.6.4-1.fc9.i386.rpm 
		    
	    	else

		    cd /usr/src/pdf_rpm
		    rpm --install pixman-0.10.0-1.fc9.i386.rpm
	    	    rpm -ifvh --replacepkgs --replacefiles cairo-1.6.4-1.fc9.i386.rpm
	    	    rpm --install pixman-devel-0.10.0-1.fc9.i386.rpm
		    rpm --install cairo-devel-1.6.4-1.fc9.i386.rpm 

		fi

	   fi;

    else
	rm -rf /var/cache/apt/archives/lock
	apt-get update
	apt-get -y install libpango1.0-0 libpango1.0-dev libpango1.0-common libpango1-ruby libcairo2 libcairo2-dev libcairo-ruby libgtk2-ruby
	cd /usr/src/mor/sh_scripts
	./ruby_cairo_upgrade.sh
    fi



							  
PDFWRAPPER=`gem list --local pdf-wrapper | grep pdf-wrapper`;
if [ "$PDFWRAPPER" == "" -a  $LOCAL_INSTALL == 0 ]; then
    download_packet pdf-wrapper-0.1.0.gem
    gem install pdf-wrapper -y --no-rdoc --no-ri --local      
elif [ $LOCAL_INSTALL == 1 ]; then 
    cd /usr/src/other/ruby_cache
    gem install pdf-wrapper -y --no-rdoc --no-ri --local;
fi

_done;
														 


if [ "$OS" == "CENTOS" ]; then


    if [ $_64BIT == 1 ]; then 

        #  gdkpixbuf2 nasty hack - die die die nasty dependancies!!!
        cp -fr /usr/src/mor/upgrade/0.7/files/gdkpixbuf2/usr/* /usr        
	
        cd /usr/src
        
        if [ $LOCAL_INSTALL == 0 ]; then
        
    	    download_packet ruby-cairo-1.5.1-1.fc9.x86_64.rpm
	    download_packet ruby-pango-0.16.0-5.fc6.x86_64.rpm
	    download_packet ruby-glib2-0.16.0-5.fc6.x86_64.rpm
            download_packet ruby-atk-0.16.0-5.fc6.x86_64.rpm

	else 
	    cd /usr/src/pdf_rpm
	fi

        rpm -ifvh --replacepkgs --replacefiles ruby-pango-0.16.0-5.fc6.x86_64.rpm ruby-glib2-0.16.0-5.fc6.x86_64.rpm ruby-atk-0.16.0-5.fc6.x86_64.rpm ruby-cairo-1.5.1-1.fc9.x86_64.rpm

    else   

        if [ $LOCAL_INSTALL == 0 ]; then

	   cd /usr/src
	    download_packet ruby-pango-0.16.0-1dc.i386.rpm
    	   download_packet ruby-atk-0.16.0-1dc.i386.rpm
	   download_packet ruby-glib2-0.16.0-1dc.i386.rpm 
	   download_packet ruby-cairo-1.5.1-1.fc9.i386.rpm

	else 
	    cd /usr/src/pdf_rpm
	fi
	
			         
      rpm -ifvh --replacepkgs --replacefiles ruby-atk-0.16.0-1dc.i386.rpm ruby-glib2-0.16.0-1dc.i386.rpm ruby-pango-0.16.0-1dc.i386.rpm ruby-cairo-1.5.1-1.fc9.i386.rpm    
    fi



fi; 
   apache_restart;

