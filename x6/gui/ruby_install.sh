#! /bin/bash

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:

. /usr/src/mor/x6/framework/bash_functions.sh


#------VARIABLES-------------

#----- FUNCTIONS ------------
ruby_installed()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2012
    # Returns:
    #   0   -   OK, ruby is present
    #   1   -   Failed, required version ruby is not present

    local ruby_version="$1"

    source "/usr/local/rvm/scripts/rvm"

    local ruby_version_present=`rvm list 2> /dev/null | grep $ruby_version | wc -l`
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

    yum --enablerepo=epel install -y gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison  libxslt-devel

    rvm reload
    rvm autolibs enable
    rvm install $RUBY_VERSION-$RUBY_PATCH_LEVEL --verify-downloads 1  # --movable  SSL no longer compiles with this option
    if [ "$?" == "0" ]; then
        report "Successfully installed Ruby $RUBY_VERSION-$RUBY_PATCH_LEVEL" 4
        rvm ruby-$RUBY_VERSION-$RUBY_PATCH_LEVEL do rvm gemset create $GEMSET_VERSION
        rvm alias create default ruby-$RUBY_VERSION-$RUBY_PATCH_LEVEL@$GEMSET_VERSION        #1.9.3 here - RVM version. 12  - gemset version
        rvm --default use $RUBY_VERSION # set as default version
        #exec su -l $USER # Reload a Linux user's group assignments without logging out to reach ruby command
        rm -fr /usr/bin/ruby # delete old symlink if such present
        ln -s /usr/local/rvm/rubies/$RUBY_VERSION/bin/ruby /usr/bin/ruby  # some scripts use /usr/bin/ruby
    else
        report "Failed to install Ruby $RUBY_VERSION-$RUBY_PATCH_LEVEL" 1
    fi
}

#--------MAIN -------------


ruby_installed ruby-2.1.2
if [ "$?" != "0" ]; then
   install_ruby_via_rvm "2.1.2" "" ""
fi

if [ `rvm list | grep 2.1.2 | wc -l` = "0" ]; then
    report "ERROR: Ruby not installed" 1
else
    report "Ruby installed, uninstalling old Ruby version" 3
    rvm uninstall ruby-2.0.0
fi

ruby -v
