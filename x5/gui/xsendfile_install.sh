#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2013
# About:    This module is available starting from MOR 12.126. It is required in order ruby would not consume plenty of on big static files download

source /usr/src/mor/x5/framework/bash_functions.sh
source /usr/src/mor/x5/framework/settings.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
check_if_xsend_configured_for_backups()
{
    XSendFile_options=`grep XSendFile /etc/httpd/conf/httpd.conf | wc -l` 
    if [ "$XSendFile_options" == "2" ]; then
        return 0 #OK
    else
        return 1 # Failed
    fi
}
#--------- Main --------------

read_mor_gui_settings
if [ "$GUI_PRESENT" == "1" ]; then  # is gui present in this system?

    mor_gui_current_version
    mor_version_mapper $MOR_VERSION_YOU_ARE_TESTING_FOR_TESTS

    MOR_MAPPED_VERSION_WEIGHT=150 # MK: nasty hack, no time to troubleshoot why this var is not set

    if [ "$MOR_MAPPED_VERSION_WEIGHT" -gt "120" ]; then
        if [ `apachectl -M 2>&1 | grep xsendfile_module | wc -l` == "1" ]; then
            report "Xsendfile Apache module is already active" 0
        else
            report "Xsendfile Apache module is not active, will try to install and activate now" 0   3

            yum -y install httpd-devel

            cd /home/mor
            bundle

            cd /usr/src/mor/x5/gui/xsendfile
            apxs -cia mod_xsendfile.c

            check_if_xsend_configured_for_backups
            if [ "$XSendFile_options" == "2" ]; then
                report "XSendFile already configured" 0
            else
                if [ "$XSendFile_options" == "0" ]; then    # options are not present yet
                    sed -i '/xsendfile_module/a\XSendFile on' /etc/httpd/conf/httpd.conf
                    sed -i '/XSendFile on/a\XSendFilePath \/usr\/local\/mor\/backups\/' /etc/httpd/conf/httpd.conf
                    check_if_xsend_configured_for_backups
                    if [ "$XSendFile_options" == "2" ]; then
                        report "XSendFile configured" 4                 
                    else
                        report "Failed to configure XSendFile. Make sure that these linces are present in /etc/httpd/conf/httpd.conf after line 'LoadModule xsendfile_module   /usr/lib/httpd/modules/mod_xsendfile.so'\n\nXSendFile on\nXSendFilePath /usr/local/mor/backups/\n" 1
                    fi
                fi
            fi

            service httpd restart &> /dev/null

            if [ `apachectl -M 2>&1 | grep xsendfile_module | wc -l` == "1" ]; then
                report "Xsendfile Apache module installed" 4
            else
                report "Failed to install Xsendfile Apache module. Manual intervention is needed, please contact Kolmisoft staff" 1
            fi
        fi
    fi
fi
