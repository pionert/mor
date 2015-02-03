#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script:
#               1. makes a backup of current Apache config: /etc/httpd/conf/httpd.conf
#               2. Install passenger gem

. /usr/src/mor/sh_scripts/install_configs.sh
. /usr/src/mor/sh_scripts/mor_install_functions.sh
. /usr/src/mor/test/framework/bash_functions.sh

#------VARIABLES-------------


#----- FUNCTIONS ------------
rake_problem_fix()
{
    # Author:   Mindaugas Mardosas
    # Year:     2011
    # About:    During deployment some problems were experienced with rake. Reinstalling rake fixes this.

    rake -v &> /dev/null
    if [ "$?" != "0" ]; then
        gem uninstall -Ix rake
        gem install rake --no-ri --no-rdoc  --version=0.9.2 
    fi
}

mv_htaccess()
{
    # Author:   Mindaugas Mardosas
    # Year:     2011
    # About:    This function move /home/mor/public/.htacces so that it would included by httpd server

    if [ -f /home/mor/public/.htaccess ]; then
            _mor_time;
            mv /home/mor/public/.htaccess /home/mor/public/.htaccess_passenger_backup_$mor_time;
            if [ -f /home/mor/public/.htaccess ]; then
                return 1
            fi
    fi
}
check_installed_gems()
{
    # Author:   Mindaugas Mardosas
    # Year:     2011
    # About:    This function checks already installed gem list against the default list of gems which are needed for MOR

    GEM_LIST=(fastthread daemon_controller spruz file-tail rack passenger)

    $(gem list > /tmp/.mor_gem_list) &> /dev/null       #listing all gems to file for quickier later access

    for element in $(seq 0 $((${#GEM_LIST[@]} - 1)))
        do
            grep ${GEM_LIST[$element]} /tmp/.mor_gem_list &> /dev/null
            if [ "$?" != "0" ]; then
                report "gem ${GEM_LIST[$element]} not found" 7
                return 1
            fi
        done
    rm -rf /tmp/.mor_gem_list
    return 0
}
backup_apache_cfg()
{
    # Author:   Mindaugas Mardosas
    # Year:     2011
    # About:    This backups apache cfg

    _mor_time;
    mkdir -p /usr/local/mor/backups/httpd_cfg
    cp /etc/httpd/conf/httpd.conf /usr/local/mor/backups/httpd_cfg/httpd.conf_before_passanger_install_script_$mor_time;
    if [ "$?" == "0" ]; then
            #echo "A backup of current httpd.conf was made: /usr/local/mor/backups/httpd_cfg/httpd.conf_before_passanger_install_script_$mor_time";
        return 0
    else
        return 1;
    fi

}
install_passanger_gems()
{
    # Author:   Mindaugas Mardosas
    # Year:     2011
    # About:    This function installs gems required for passenger
    #
    #       fastthread-1.0.7
    #       daemon_controller-0.2.5
    #       spruz-0.2.2
    #       file-tail-1.0.5
    #       rack-1.2.1
    #       passenger-3.0.2

    yum -y install curl curl-devel &> /dev/null

    cd /usr/src
    rm -rf passenger_gems
    download_packet passenger_gems.tar.gz &> /dev/null
    tar zxvf passenger_gems.tar.gz &> /dev/null

    cd passenger_gems
    gem install fastthread daemon_controller spruz file-tail rack passenger --no-rdoc --no-ri --local >> /dev/null
    check_installed_gems
    if [ "$?" != "0" ]; then
        echo "Install the gems manually and run the script again"
        return 1
    fi
    RESTART_NEEDED=1
}

install_passanger()
{
    # Author:   Mindaugas Mardosas
    # Year:     2011
    # About:    This function checks if passenger module is already installed
    #

    if [ ! -f "/usr/lib64/ruby/gems/1.8/gems/passenger-3.0.2/ext/apache2/mod_passenger.so" ] && [ ! -f "/usr/lib/ruby/gems/1.8/gems/passenger-3.0.2/ext/apache2/mod_passenger.so" ] ; then
        passenger-install-apache2-module -a
        RESTART_NEEDED=1
        return $?
    fi
}

install_passanger_module_configuration()
{
    # Author:   Mindaugas Mardosas
    # Year:     2011
    # About:    This function installs passanger module configuration


    grep "mod_passenger.so" /etc/httpd/conf/httpd.conf &> /dev/null
    if [ "$?" != "0" ]; then
        unalias cp &> /dev/null
        local arch=`uname -m`
        if [ "$arch" == "x86_64" ]; then
            cp /usr/src/mor/test/files/httpd/passenger/httpd_passenger_64.conf /etc/httpd/conf/httpd.conf
        else
            cp /usr/src/mor/test/files/httpd/passenger/httpd_passenger_32.conf /etc/httpd/conf/httpd.conf
        fi
        grep "mod_passenger.so" /etc/httpd/conf/httpd.conf &> /dev/null
        if [ "$?" != "0" ]; then
            return 1;
        fi

        RESTART_NEEDED=1
    fi

}

#--------MAIN -------------
svn update /usr/src/mor

RESTART_NEEDED=0    #if this wariable will be set to 1 - httpd will be restarted

grep CentOS /etc/redhat-release &> /dev/null
if [ "$?" != "0" ]; then
    echo "Sorry, only CentOS supported";
    exit 1
fi
rake_problem_fix
mv_htaccess
if [ "$?" != "0" ]; then
    report "Failed to rename .htaccess in /home/mor/public" 1
    exit 1
fi

install_passanger_gems
if [ "$?" != "0" ]; then
    report "Failed to install passenger gems" 1
    exit 1
fi

backup_apache_cfg
if [ "$?" != "0" ]; then
    report "Failed to backup existing apache cfg" 1
    exit 1
fi
install_passanger
if [ "$?" != "0" ]; then
    report "Failed to install passenger module" 1
    exit 1
fi
install_passanger_module_configuration
if [ "$?" == "0" ]; then
    report "Passanger successfully installed" 0
else
    report "Failed to install passenger module configuration" 1
    exit 1
fi



if [ "$RESTART_NEEDED" == "1" ]; then
    /etc/init.d/httpd restart
fi
