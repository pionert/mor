#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
ruby_1_9_3_installed()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # Returns:
    #   0   -   OK, ruby is present
    #   1   -   Failed, required version ruby is not present
    
    local ruby_version="$1"
    local gemset="$2"
    
    source "/usr/local/rvm/scripts/rvm"
    
    local ruby_version_present=`rvm $ruby_version do rvm list 2> /dev/null | grep 1.9.3 | wc -l`
    if [ "$ruby_version_present" == "0" ]; then
        return 1
    else
        return 0
    fi
}
install_ruby_1_9_3()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    
    
    if [ ! -f /etc/yum.repos.d/epel.repo ]; then
        report "Epel repo not found, installing epel repo" 3
        _centos_version
        if [ "$centos_version" == "5" ]; then
            rpm -Uvh http://mirror.duomenucentras.lt/epel/5/i386/epel-release-5-4.noarch.rpm
        else
            rpm -Uvh http://mirror.duomenucentras.lt/epel/6/i386/epel-release-6-8.noarch.rpm 
        fi
        
        if [ ! -f /etc/yum.repos.d/epel.repo ]; then
            report "Failed to install epel repo. Most probably version number changed, try to install manually by increasing version number in this command: rpm -Uvh http://mirror.duomenucentras.lt/epel/6/i386/epel-release-6-8.noarch.rpm    and run the script again" 1
        fi
    fi
    
    yum --enablerepo=epel install -y gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel libxslt-devel
    
    #if -[ -f /usr/local/rvm/scripts/rvm  ]; then
    #    source "/usr/local/rvm/scripts/rvm" #Loading RVM as function
    #else
    #    report "RVM is not installed correctly" 1
    #    exit 1
    #fi
    #rvm_is_installed
    #if [ "$?" != "0" ]; then
    #    /usr/src/mor/upgrade/12/rvm.sh
    #    source "/usr/local/rvm/scripts/rvm"
    #    rvm_is_installed
    #    if [ "$?" != "0" ]; then
    #        report "Failed to install RVM, cannot continue. Launch the script again or install ruby RVM manually" 1
    #        exit 1
    #    fi
    #fi
    rvm all do pkg install libyaml iconv psych
    rvm install 1.9.3-p194 --patch /usr/src/mor/test/files/patches/ssl_no_ec2m.patch --verify-downloads 1 # --movable  no longer compiles SSL with this option

 

    if [ "$?" == "0" ]; then
        report "Successfully installed Ruby 1.9.3" 4
        
     #   source "/usr/local/rvm/scripts/rvm"
     #   if [ `rvm 1.9.3 do rvm gemset list | grep 12 | wc -l` != 1 ]; then
     #       rvm 1.9.3 do rvm gemset create 12
     #   fi
        #rvm use ruby-1.9.3-p194
        rvm ruby-1.9.3-p194 do rvm gemset create 12
        rvm alias create default ruby-1.9.3-p194@12        #1.9.3 here - RVM version. 12  - gemset version
    else
        report "Failed to install Ruby 1.9.3" 1
    fi
}

#--------MAIN -------------

ruby_1_9_3_installed ruby-1.9.3-p194 12
if [ "$?" != "0" ]; then
    install_ruby_1_9_3
fi

