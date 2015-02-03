#! /bin/sh

# Author:   Mindaugas Mardosas
# Year:     2012
# About:    This libary is only required for MOR 12+

. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
nodejs_install()
{
    # Author:   Mindaugas Mardosas
    # Year:     2012
    # About:    This function istalls nodejs if MOR 12+ is detected
    
    mor_gui_current_version
    mor_version_mapper "$MOR_VERSION"
    if [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "123" ]; then
            
        if [ ! -L /usr/bin/nodejs ] && [ ! -f "/usr/bin/nodejs" ]; then
            cd /usr/src
            
            wget -c http://www.kolmisoft.com/packets/node-v0.6.9.tar.gz
            tar xzvf node-v0.6.9.tar.gz
            cd node-v0.6.9
            ./configure
            make
            make install
            ln /usr/local/bin/node /usr/bin/nodejs
            ln /usr/local/bin/node /usr/bin/node
        else
            report "Nodejs is already present" 0
        fi
    fi
}
#--------MAIN -------------
if [ -f "/etc/yum.repos.d/nodejs-stable.repo" ]; then      # removing legacy repository
    rm -rf /etc/yum.repos.d/nodejs-stable.repo
    yum clean all    
fi
nodejs_install
