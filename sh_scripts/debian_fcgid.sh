#!/bin/sh
#==== Includes=====================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#==================================================

cd /usr/src/mor
. "$(pwd)"/sh_scripts/install_configs.sh

echo -e "echo Installing FCGID\n-----------------------------------------------\n"

apt-get -y install libfcgi-ruby1.8 libapache2-mod-fcgid


      #wget http://fastcgi.coremail.cn/mod_fcgid.1.09.tar.gz
      #wget http://www.kolmisoft.com/files/packages/mod_fcgid.1.09.tar.gz
download_packet mod_fcgid.1.09.tar.gz
extract_gz mod_fcgid.1.09.tar.gz

cd mod_fcgid.1.09
rm -fr Makefile
touch Makefile

echo "#
#  Makefile for Apache2
#

builddir     = .
top_dir      = /usr/share/apache2

top_srcdir   = \${top_dir}
top_builddir = \${top_dir}
VPATH = arch/unix/

include \${top_builddir}/build/special.mk

APXS      = apxs
APACHECTL = apachectl
EXTRA_CFLAGS = -I\$(builddir)

#DEFS=-Dmy_define=my_value
#INCLUDES=-Imy/include/dir
INCLUDES=-I /usr/include/apache2 -I /usr/include/apr-0
#LIBS=-Lmy/lib/dir -lmylib

all: local-shared-build

clean:" >> /usr/src/mod_fcgid.1.09/Makefile
echo -e "\t-rm -f *.o *.lo *.slo *.la" >> /usr/src/mod_fcgid.1.09/Makefile
make install

cp /usr/src/mor/apache2-conf/fcgid.conf /etc/apache2/mods-available 
a2enmod fcgid

apache_restart
