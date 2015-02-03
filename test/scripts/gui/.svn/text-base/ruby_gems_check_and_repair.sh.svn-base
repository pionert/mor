#! /bin/sh

FIRST_INSTALL="$1"

# Author:   Mindaugas Mardosas
# Year:     2010
# About:    This script checks if all required ruby gems are installed and tries to download and install missing gems

# Arguments:
    # 1 - "first" //indicates that this script is run to install gems for the first time. Displays OK instead of Fixed
    # no arguments - checks and tries to repair if some gems are missing

    #Example usage:
        # Example 1
            #./ruby_gems_check_and_repair.sh first  #use this if installing gems for the first time
        # Example 2
            #./ruby_gems_check_and_repair.sh        #default, reports "FIXED" if some gems were missing and installed

# Returns:
    #   0 - OK
    #   1 - Failed

. /usr/src/mor/test/framework/bash_functions.sh

#================
ruby_gem()
{
    # Author:   Mindaugas Mardosas
    # Year:     2010
    # About:    This function checks if a command: "gem" is available in the system. If not - installs it

    # Arguments:
    # 1 - "first" //indicates that this script is run to install gems for the first time. Displays OK instead of Fixed
    # no arguments - checks and tries to repair if some gems are missing


    # Returns:
        #   0   -   OK
        #   1   -   FAILED to install "gem" command

    gem list &> /dev/null
    if [ "$?" != "0" ]; then
        /bin/sh /usr/src/mor/sh_scripts/gem_version_check_and_repair.sh &> /dev/null
        if [ "$?" == "0" ]; then
            if [ "$FIRST_INSTALL" == "first" ]; then
                report "Ruby gem command" 0
                return 0
            else
                report "Ruby gem command" 4
                return 0
            fi
        else
            report "Ruby gem command" 1
            exit 1;
        fi
    fi
}
#================
install_gems()
{
    # Author:   Mindaugas Mardosas
    # Year:     2010
    # About:    This function downloads and installs required Ruby gems from MOR repository if one or more gems are missing

    mkdir -p /usr/src/other/ruby_cache/old
    mv /usr/src/other/ruby_cache/*.gem /usr/src/other/ruby_cache/old/  &> /dev/null
    cd /usr/src/other/ruby_cache/

    rm -rf gem_pack.tar.gz
    report "Downloading gems" 7
    wget -c http://www.kolmisoft.com/packets/gem_pack.tar.gz &> /dev/null

    if [ ! -f /bin/tar ]; then
        report "Installing tar archiver" 7
        yum -y install tar  >> /dev/null
    fi

    tar xzf gem_pack.tar.gz >> /dev/null
    if [ "$?" != "0" ]; then
        report "Failed to extract Ruby gems" 1
        exit 1
    fi


    gem install mysql --version=2.7 --no-rdoc --no-ri -- --with-mysql-config=/usr/bin/mysql_config >> /dev/null

    gem install archive-tar-minitar rubyforge rake hoe color transaction-simple pdf-writer pdf-wrapper activesupport \
                activerecord builder actionpack actionmailer actionwebservice fcgi json_pure  --no-rdoc --no-ri --local >> /dev/null

    gem install rails -v=1.2.6 --include-dependencies --no-rdoc --no-ri --local >> /dev/null

    /etc/init.d/httpd restart #&> /dev/null

    apache_is_running   #checking if httpd is OK after restart
    if [ "$?" != "0" ]; then
        report "Apache web server is not running!" 1;
    fi

}
#===================================
check_installed_gems()
{
    # Author:   Mindaugas Mardosas
    # Year:     2010
    # About:    This function checks already installed gem list against the default list of gems which are needed for MOR

    _centos_version
    if [ "$centos_version" -gt "5" ]; then    # >=5
        GEM_LIST=(mysql archive-tar-minitar rubyforge rake hoe color transaction-simple pdf-writer pdf-wrapper activesupport activerecord builder actionpack actionmailer actionwebservice rails json_pure)
    else
        GEM_LIST=(mysql archive-tar-minitar rubyforge rake hoe color transaction-simple pdf-writer pdf-wrapper activesupport activerecord builder actionpack actionmailer actionwebservice fcgi rails json_pure)
    fi

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

#============= MAIN ======================

apache_is_running
APACHE_STATUS="$?"  #is Apache running?

gui_exists
GUI_STATUS="$?" #is gui present?


mor_gui_current_version
mor_version_mapper "$MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS"
if [ "$APACHE_STATUS" != "0" ] || [ "$GUI_STATUS" != "0" ] && [ "$FIRST_INSTALL" != "first" ] || [ "$MOR_MAPPED_VERSION_WEIGHT" -ge "123" ]; then     #is MOR GUI installed in the system?
    exit 0
fi

ruby_gem
check_installed_gems

if [ "$?" != "0" ]; then
    install_gems
    check_installed_gems
    if [ "$?" != "0" ]; then
        report "Failed to install all required ruby gems. Please contact Kolmisoft support staff: http://support.kolmisoft.com" 1
        exit 1
    else
        if [ "$FIRST_INSTALL" == "first" ]; then
            report "Ruby gems" 0
            exit 0  #ok
        else
            report "\tRuby gems" 4
            exit 4  #ok
        fi
    fi
else
    report "Ruby gems" 0
    exit 0  #ok
fi
