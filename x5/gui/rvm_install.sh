#! /bin/bash

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:

. /usr/src/mor/x5/framework/bash_functions.sh

#------VARIABLES-------------
FIRST_INSTALL="$1"
#----- FUNCTIONS ------------
install_rvm()
{
    # Author: Mindaugas Mardosas
    # Year:  2011
    #   About:  This function checks if rvm (ruby version manager) is installed in the system.
    #
    #   Returns:
    #       0   -   OK
    #       1   -   FAILED 

    if [ ! -f "/usr/local/rvm/scripts/rvm" ]; then
        #==== yum bug
        yum clean metadata
        yum clean all
        #===============
        yum -y install mc bc wget curl make git bzip2 gcc openssl openssl-devel zlib zlib-devel sudo
        _centos_version
        if [ "$centos_version" == "5" ]; then
        #   ----------Autoconf install-----------
            cd /usr/src/ 
            wget -c http://ftp.gnu.org/gnu/autoconf/autoconf-2.63.tar.gz
            tar xvzf autoconf-2.63.tar.gz
            cd autoconf-2.63
            ./configure --prefix=/usr
            make
            make install
            cd ..
        else    # 6.x and later
            yum -y install autoconf
        fi
        #== rvm
        cd /usr/src
        report "Downloading RVM install script from https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer" 3
        wget -c https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer --no-check-certificate
        sh rvm-installer stable

        if [ -f "/usr/local/rvm/scripts/rvm" ]; then
            report "RVM successfully installed" 4
        else
            report "Failed to install RVM, cannot continue until this problem is fixed. Please fix it manualy" 1
            exit 1
        fi
        #=====
    else

        report "RVM already installed" 0

        source "/etc/profile.d/rvm.sh"

        rvm get stable
        rvm autolibs enable

    fi
}
#--------MAIN -------------

gpg2 --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3

install_rvm

source /etc/profile.d/rvm.sh

rvm reload
