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
    if [ "$MOR_VERSION" -ge "12" ]; then
        if [ -f /usr/bin/node ]; then
            report "Nodejs is installed" 0
        else
            cd /usr/src
            wget -c http://nodejs.tchol.org/repocfg/el/nodejs-stable-release.noarch.rpm
            yum -y localinstall --nogpgcheck nodejs-stable-release.noarch.rpm
            yum -y install nodejs-compat-symlinks npm
            
            if [ -f /usr/bin/node ]; then
                report "Nodejs is installed" 4
            else
                report "Failed to install Nodejs. For details how it is being installed please check this script: /usr/src/mor/sh_scripts/nodejs.sh" 1
            fi
        fi
    fi
}
#--------MAIN -------------
nodejs_install
