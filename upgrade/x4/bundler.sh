#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script install ruby bundler

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
check_if_bundler_installed()
{
    # Author:   Mindaugas Mardosas
    # Year:     2012
    # About:    This  function checks if ruby bundler is installed
    # Returns:
    #   0   -   OK, bundler is already installed
    #   1   -   Failed, bundler is not installed
    
    local ruby_version="$1"
    local gemset="$2"
    
    
    r_bundler=`rvm $ruby_version@$gemset do gem list | grep bundler | wc -l`
    if [ "$r_bundler" == "1" ]; then
        R_BUNDLER="0"
        return 0
    else
        R_BUNDLER="1"
        return 1
    fi
}

install_bundler()
{
    # Author:   Mindaugas Mardosas
    # Year:     2012
    # About:    This  function installs ruby bundler
    
    local ruby_version="$1"
    local gemset="$2"
 
    source "/usr/local/rvm/scripts/rvm"
 
    rvm $ruby_version@$gemset do gem install bundler
    cd /home/mor

    # this file should be empty and readable
    rm -fr /home/mor/Gemfile.lock 
    touch /home/mor/Gemfile.lock 
    chmod 666 /home/mor/Gemfile.lock     

    rvm $ruby_version@$gemset do bundle update
}

#--------MAIN -------------

check_if_bundler_installed ruby-1.9.3-p327 x4
if [ "$?" != "0" ]; then
    install_bundler ruby-1.9.3-p327 x4
fi