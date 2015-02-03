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
install_ruby_via_rvm()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # About:    This function installs required Ruby version with requested patch level via RVM. It also creates a gemset according to MOR version
    #
    # Arguments:
    #   1 - ruby_version
    #   2 - path_level
    #   3 - gemset version to create
    
    local RUBY_VERSION="$1"
    local RUBY_PATCH_LEVEL="$2"
    local GEMSET_VERSION="$3"
    
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
    
    rvm pkg install libyaml iconv psych
    rvm install $RUBY_VERSION-$RUBY_PATCH_LEVEL --patch /usr/src/mor/test/files/patches/ssl_no_ec2m.patch --verify-downloads 1 # --movable  SSL no longer compiles with this option
    if [ "$?" == "0" ]; then
        report "Successfully installed Ruby $RUBY_VERSION-$RUBY_PATCH_LEVEL" 4
        rvm ruby-$RUBY_VERSION-$RUBY_PATCH_LEVEL do rvm gemset create $GEMSET_VERSION
        rvm alias create default ruby-$RUBY_VERSION-$RUBY_PATCH_LEVEL@$GEMSET_VERSION        #1.9.3 here - RVM version. 12  - gemset version
    else
        report "Failed to install Ruby $RUBY_VERSION-$RUBY_PATCH_LEVEL" 1
    fi
}

#--------MAIN -------------

ruby_1_9_3_installed ruby-1.9.3-p327 x4 "p327"
if [ "$?" != "0" ]; then
    install_ruby_via_rvm "1.9.3" "p327" "x4"
fi

