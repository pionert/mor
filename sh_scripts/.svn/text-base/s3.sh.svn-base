#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2012
# About:    This script installs Amazon S3 support

. /usr/src/mor/test/framework/bash_functions.sh
. /usr/src/mor/test/framework/settings.sh

#------VARIABLES-------------
OPTION="$1"

if [ "$OPTION" != "INSTALL" ] && [ "$OPTION" != "UNINSTALL" ]; then
    report "Neither INSTALL neither UNINSTALL option is provided. What should I do?" 3
    exit 0
fi
#----- FUNCTIONS ------------
install_s3tools()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function installs s3cmd packets. Original website: http://s3tools.org
    
    cd /usr/src/
    os_processor_type
    _centos_version
    if [ "$centos_version" == "5" ]; then       
        
        curl "http://www.kolmisoft.com/packets/el5/s3cmd/s3cmd-0.9.9.91-1.el5.1.noarch.rpm" > s3cmd-0.9.9.91-1.el5.1.noarch.rpm
        #curl "http://www.kolmisoft.com/packets/el5/s3cmd/s3cmd-1.0.0-4.1.i386.rpm" > s3cmd-1.0.0-4.1.i386.rpm
        #curl "http://www.kolmisoft.com/packets/el5/s3cmd/s3cmd-1.0.0-4.1.x86_64.rpm" > s3cmd-1.0.0-4.1.x86_64.rpm
        
        #if [ "$_64BIT" == "1" ]; then
        #    #64 bit
        #    yum --nogpgcheck -y install s3cmd-1.0.0-4.1.x86_64.rpm s3cmd-0.9.9.91-1.el5.1.noarch.rpm gpg
        #else
        #    #32 bit
        #    yum --nogpgcheck -y install s3cmd-1.0.0-4.1.i386.rpm s3cmd-0.9.9.91-1.el5.1.noarch.rpm gpg
        #fi        
        yum --nogpgcheck -y install s3cmd-0.9.9.91-1.el5.1.noarch.rpm gpg
        
    elif [ "$centos_version" == "6" ]; then
        #curl "http://www.kolmisoft.com/packets/el6/s3cmd/s3cmd-1.0.0-4.1.i386.rpm" > s3cmd-1.0.0-4.1.i386.rpm
        #curl "http://www.kolmisoft.com/packets/el6/s3cmd/s3cmd-1.0.0-4.1.x86_64.rpm" > s3cmd-1.0.0-4.1.x86_64.rpm
        curl "http://www.kolmisoft.com/packets/el6/s3cmd/s3cmd-1.0.1-1.el6.noarch.rpm" > s3cmd-1.0.1-1.el6.noarch.rpm
        
        yum --nogpgcheck -y install s3cmd-1.0.1-1.el6.noarch.rpm  gpg
        
        #if [ "$_64BIT" == "1" ]; then
            #64 bit
            #yum --nogpgcheck -y install s3cmd-1.0.0-4.1.x86_64.rpm s3cmd-1.0.1-1.el6.noarch.rpm  gpg     
        #else
            #32 bit
        #    yum --nogpgcheck -y install s3cmd-1.0.0-4.1.i386.rpm s3cmd-1.0.1-1.el6.noarch.rpm  gpg     
        #fi

    else
        report "Your CentOS version is not supported. Visit http://s3tools.org/repositories to check what repository you should add" 1
        exit 1
    fi
    
    if [ -f /usr/bin/s3cmd ]; then
        report "s3cmd installed" 0
    else
        report "Failed to isntall s3cmd" 1  
    fi
    
}
create_s3_crontab()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function creates crontab for S3 DB backup
    #
    #   Arguments:
    #       $1  -   database hostname
    #       $2  -   database username
    #       $3  -   database password
    #       $4  -   database name
    
    local DB_HOSTNAME=$1
    local DB_USER_NAME=$2
    local DB_PASSWORD=$3
    local DB_NAME=$4

    
    echo "
    # daily MySQL backup to S3 (not on first day of month or sundays)                                                                                                                                                    
    0 3 2-31 * 1-6 root sh /usr/local/mor/s3.sh day 
    
    # weekly MySQL backup to S3 (on sundays, but not the first day of the month)                                                                                                                                         
    0 3 2-31 * 0 root sh /usr/local/mor/s3.sh week
    
    # monthly MySQL backup to S3                                                                                                                                                                                         
    0 3 1 * * root sh /usr/local/mor/s3.sh month
    " > /etc/cron.d/kolmisoft_s3_backup
}

create_config()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2012
    #   About:  This function creates configuration for Amazon S3 tool s3cmd
    
    if [ -f /root/.s3cfg ]; then
        report "/root/.s3cfg configuration found, that means that Kolmisoft S3 backup tool is already installed. If you would like to restart installation from scratch - please delete that file" 3
        exit 1
    fi
    
    echo "Please enter S3 Access key ID:"
    read access_key
    
    echo "Please enter S3 Secret Access Key:"
    read secret_key
    
    echo "Please enter Server ID which matches the one in Kolmisoft support system"
    read USER_PATH
    
    
    #DB dump is later deleted by script
    echo "Please specify temporary DIR for DB dump storage before uploading it to Cloud. This directory must have enough space to store entire DB dump. Hit enter for default: /tmp"
    read TMP_DIR
    if [ "$TMP_DIR" == "" ]; then
        TMP_DIR="/tmp"
    fi
    
    while [ ! -d "$TMP_DIR" ]; do   # Iterating while correct path is provided
        report "Your provided TMP dir path is invalid. Make sure provided path exists and is folder" 3
        read TMP_DIR
    done
    
    if [ `expr substr $TMP_DIR ${#TMP_DIR} 1` != "/" ]; then    # Cheking if directory path ends with slash at the end
        echo "TMP_DIR=$TMP_DIR/" > /usr/local/mor/s3_configuration
    else
        echo "TMP_DIR=$TMP_DIR" > /usr/local/mor/s3_configuration
    fi
        
    echo "[default]
access_key = $access_key
bucket_location = US
cloudfront_host = cloudfront.amazonaws.com
cloudfront_resource = /2010-07-15/distribution
default_mime_type = binary/octet-stream
delete_removed = False
dry_run = False
encoding = UTF-8
encrypt = False
follow_symlinks = False
force = False
get_continue = False
gpg_command = /usr/bin/gpg
gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_passphrase = kolmisoft
guess_mime_type = True
host_base = s3.amazonaws.com
host_bucket = %(bucket)s.s3.amazonaws.com
human_readable_sizes = False
list_md5 = False
log_target_prefix = 
preserve_attrs = True
progress_meter = True
proxy_host = 
proxy_port = 0
recursive = False
recv_chunk = 4096
reduced_redundancy = False
secret_key = $secret_key
send_chunk = 4096
simpledb_host = sdb.amazonaws.com
skip_existing = False
socket_timeout = 10
urlencoding_mode = normal
use_https = True
verbosity = WARNING
USER_PATH = $USER_PATH/
" > /root/.s3cfg
    report "/root/.s3cfg configuration written" 4
}

#--------MAIN -------------
if [ "$OPTION" == "INSTALL" ]; then
    
    are_we_inside_screen
    if [ "$?" == "1" ]; then
        report "You must run this script from 'screen' program, because after install daily, weekly and monthly backups will be made which can take a lot of time"   1
        exit 1
    fi    
    
    report "Now will sync system time with ntp.ubuntu.com" 3
    ntpdate ntp.ubuntu.com &> /dev/null
    
    install_s3tools
    
    create_config
    mkdir -p /usr/local/mor
    cp -fr /usr/src/mor/test/files/s3.sh /usr/local/mor/s3.sh    #copying backup script
    create_s3_crontab
    if [ -f /root/.s3cfg ] && [ -f /etc/cron.d/kolmisoft_s3_backup ]; then
        report "Kolmisoft Amazon S3 backup tool was installed" 4
    fi
    
    report "Creating daily backup" 3
    /bin/sh /usr/local/mor/s3.sh day
    
    report "Creating weekly backup" 3
    /bin/sh /usr/local/mor/s3.sh week
    
    report "Creating monthly backup" 3
    /bin/sh /usr/local/mor/s3.sh month        
    
elif [ "$OPTION" == "UNINSTALL" ]; then
    rm -rf /root/.s3cfg  /etc/cron.d/kolmisoft_s3_backup
    if [ ! -f /root/.s3cfg ] && [ ! -f /etc/cron.d/kolmisoft_s3_backup ]; then
        report "Kolmisoft Amazon S3 backup configurations deleted"  3
    else
        report "Failed to delete /root/.s3cfg  and /etc/cron.d/kolmisoft_s3_backup"  3
    fi
fi
