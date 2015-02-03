#! /bin/bash

sipsak --help &> /dev/null
if [ "$?" == "0" ]; then 
	echo "===== Sipsak is already installed ====";
	chmod  +s /usr/bin/sipsak
	exit 0;
fi

. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh
. /usr/src/mor/test/framework/bash_functions.sh



#=== INSTALLING sipsak ======
echo "===INSTALLING SIPSAK==="
which_os

if [ "$OS" == "DEBIAN" ]; then 
	apt-get install sipsak;
elif [ "$OS" == "CENTOS" ]; then
      _centos_version
      if [ "$centos_version" == "6" ]; then
          processor_type
          if [ "$_64BIT" == "1" ]; then
              download_packet gnutls-2.5.3-1rt.x86_64.rpm
              rpm --force -Uvh gnutls-2.5.3-1rt.x86_64.rpm  #   original gnutls-devel packet in CentOS 6 is missing the openssl.h header file required for sipsak
          else
              download_packet gnutls-2.5.3-1rt.i686.rpm
              rpm --force -Uvh gnutls-2.5.3-1rt.i686.rpm  #   original gnutls-devel packet in CentOS 6 is missing the openssl.h header file required for sipsak
          fi
      else
          yum -y install gnutls-devel
      fi

	download_packet sipsak-0.9.6-1.tar.gz
	extract_gz sipsak-0.9.6-1.tar.gz
	cd sipsak-0.9.6
	./configure
	make
	cp sipsak /usr/bin/
fi

chmod  +s /usr/bin/sipsak

sipsak --help > /dev/null
if [ "$?" == "0" ]; then 
	echo "===== Sipsak was installed successfully ====";
else
	echo "===== Sipsak installation failed!!!!!!!!====";
	wait_user #if installation have failed - stop if stops are enabled.
fi
#============================

