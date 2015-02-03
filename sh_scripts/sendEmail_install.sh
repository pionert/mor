#!/bin/sh
#==== Includes=====================================
   cd /usr/src/mor
   . "$(pwd)"/sh_scripts/install_configs.sh
#==================================================

if [ $LOCAL_INSTALL == 0 ]; then
   if [ -r /etc/redhat-release ]; then       
       yum -y install perl-Net-SSLeay perl-IO-Socket-SSL
   else
       apt-get -y install libidn11 libidn11-dev libnet-libidn-perl libio-socket-ssl-perl libnet-ssleay-perl

       # perl -MCPAN -e "force install Net::LibIDN"
       # perl -MCPAN -e "force install Net::SSLeay"
       # perl -MCPAN -e "force install IO::Socket::SSL"

       # if IO::Socket::SSL install failed, do it manually:
       # perl -MCPAN -e shell
       # force install IO::Socket::SSL
   fi;
fi


mkdir -p /usr/local/mor
cp -fr /usr/src/mor/scripts/sendEmail /usr/local/mor

cd /usr/src/mor/fax2email/agi/
./install.sh

