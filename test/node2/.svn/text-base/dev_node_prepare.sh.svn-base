#! /bin/sh

#   About:  This script will preper dev environment for CentOS 6


yum -y update

yum -y install screen

yum -y groupinstall "X Window System" "Desktop" 
yum -y install xorg-x11-fonts-misc xorg-x11-fonts-Type1 kdesvn thunderbird firefox git mc


# Manually install:
# Google Chrome

echo 'su - -c "/bin/bash startx" root' >> /etc/rc.local


#rpm -Uvh http://mirror.duomenucentras.lt/epel/6/i386/epel-release-6-8.noarch.rpm # atrodo per mor install sudeda
yum --enablerepo=epel install meld

#SKype
yum -y install pulseaudio-libs.i686 pulseaudio-libs-devel.i686 alsa-plugins-pulseaudio.i686 \
libv4l.i686 libXv.i686 libXv-devel.i686 libXScrnSaver.i686 libXScrnSaver-devel.i686 \
dbus-qt.i686 dbus-qt-devel.i686 qt.i686 qt-devel.i686

# Thunderbird
yum -y install dbus-glib.i686 gtk2.i686 libXt.i686

# Development tools
yum -y install subversion git gcc make gcc-c++ kdesvn

# Editors
yum -y install vim-enhanced mc


# Yakuake
yum -y install kdelibs kdebase wget
rpm -Uvh http://www.kolmisoft.com/packets/sl/yakuake-2.9.6-2.fc12.x86_64.rpm

# Keepass
rpm -Uvh http://www.kolmisoft.com/packets/sl/keepassx-0.4.3-1.puias6.x86_64.rpm

# Filezilla
yum --enablerepo=epel install filezilla

# OpenOffice
yum -y install libreoffice-base libreoffice-writer libreoffice-calc libreoffice-impress

# Gimp
yum -y install gimp

# Basket užrašams

cd /usr/src
wget -c http://www.kolmisoft.com/packets/sl/basket-1.0.3.1-8.el6.x86_64.rpm
yum -y --nogpgcheck install basket-1.0.3.1-8.el6.x86_64.rpm  # If you have 64 bit system

# Archiving
yum -y install file-roller bzip2 unrar

#--- Disable not needed services ------

chkconfig --levels 2345 iptables off
chkconfig --levels 2345 asterisk off
service iptables stop
service asterisk stop