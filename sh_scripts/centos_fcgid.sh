#!/bin/sh
#========================================
    . /usr/src/mor/sh_scripts/install_configs.sh
    . /usr/src/mor/sh_scripts/mor_install_functions.sh
#========================================
         
processor_type;
# Is system 64bit?
# check with: uname -a
#_64BIT=0
echo -e "echo Installing FCGID\n-----------------------------------------------\n"
        if [ "$LOCAL_INSTALL" == "0" ]; then 
                yum install -y apr-devel httpd-devel
                #=========== FCGI =====================
                download_packet fcgi-2.4.0.tar.gz;
                tar -xzf fcgi-2.4.0.tar.gz
                cd fcgi-2.4.0
                ./configure
                make
                make install
                #========= FCGID =====================
                download_packet mod_fcgid.1.09.tar.gz;
                tar -xzf mod_fcgid.1.09.tar.gz
                cd mod_fcgid.1.09
                /bin/rm -fr Makefile
                touch Makefile
                #===============================
if [ $_64BIT == 0 ]; then
    echo "#
#  Makefile for Apache2
#
builddir     = .
top_dir      = /usr/lib/httpd
top_srcdir   = \${top_dir}
top_builddir = \${top_dir}
VPATH = arch/unix/
include \${top_builddir}/build/special.mk
APXS      = apxs
APACHECTL = apachectl
EXTRA_CFLAGS = -I\$(builddir)
#DEFS=-Dmy_define=my_value
#INCLUDES=-Imy/include/dir
INCLUDES=-I /usr/include/httpd -I /usr/include/apr-0
#LIBS=-Lmy/lib/dir -lmylib
all: local-shared-build
clean:" >> /usr/src/mod_fcgid.1.09/Makefile
    echo -e "\t-rm -f *.o *.lo *.slo *.la" >> /usr/src/mod_fcgid.1.09/Makefile
    make install
else
    echo "#
#  Makefile for Apache2
#
builddir     = .
top_dir      = /usr/lib64/httpd
top_srcdir   = \${top_dir}
top_builddir = \${top_dir}
VPATH = arch/unix/
include \${top_builddir}/build/special.mk
APXS      = apxs
APACHECTL = apachectl
EXTRA_CFLAGS = -I\$(builddir)
#DEFS=-Dmy_define=my_value
#INCLUDES=-Imy/include/dir
INCLUDES=-I /usr/include/httpd -I /usr/include/apr-0
#LIBS=-Lmy/lib/dir -lmylib
all: local-shared-build
clean:" >> /usr/src/mod_fcgid.1.09/Makefile
    echo -e "\t-rm -f *.o *.lo *.slo *.la" >> /usr/src/mod_fcgid.1.09/Makefile
    make install
fi
else
        rpm -Uvh /usr/src/fcgi-2.4.0-1.i386.rpm /usr/src/mod_fcgid-1.09-1.i386.rpm
fi
#=====================================

download_packet ruby-fcgi-0.8.6.tar.gz
tar zxvf ruby-fcgi-0.8.6.tar.gz
cd ruby-fcgi-0.8.6
ruby install.rb config
ruby install.rb setup
ruby install.rb install

if [ $LOCAL_INSTALL == 0 ]; then
   gem install fcgi --both -y --no-rdoc --no-ri
elif [ $LOCAL_INSTALL == 1 ]; then
   cd /usr/src/other/ruby_cache
   gem install fcgi --both -y --no-rdoc --no-ri --local 
fi

echo "
LoadModule fcgid_module modules/mod_fcgid.so
<IfModule mod_fcgid.c>
    IdleTimeout 600
    BusyTimeout 6000
    ProcessLifeTime 3600
    MaxProcessCount 16
    DefaultMinClassProcessCount 3
    DefaultMaxClassProcessCount 30
    IPCConnectTimeout 8
    IPCCommTimeout 6000
</IfModule>" > /etc/httpd/conf.d/mod_fcgid_include.conf 


