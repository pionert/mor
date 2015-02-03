#! /bin/sh

# Author:   Mindaugas Mardosas
# Company:  Kolmisoft
# Year:     2011
# About:    This script checks if DIDWW provider already exists in MOR database. If not - it is added.
#
#   Internal logic:
#       1. Script checks if:
#           /etc/asterisk/extensions_mor_didww.conf
#           [from-didww] 
#           exten => _X.,1,Set(CDR(ACCOUNTCODE)=0) <--------- 0 exists, that means that DIDWW was not yet configured in MOR system
#           exten => _X.,2,Goto(mor,${EXTEN},1)

. /usr/src/mor/x5/framework/bash_functions.sh

#------VARIABLES-------------

#----- FUNCTIONS ------------
required_cfg_exists()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks if all required configurations exists
    #
    # Parameters:
    #   $1  -   exit_on_failure
    #
    # Returns:
    #   0   -   OK, all files are present
    #   1   -   Some files are missing

    local PARAM="$1";

    if [ ! -f /etc/asterisk/extensions_mor.conf ] || [ ! -f /etc/asterisk/sip.conf ]; then
        if [ "$PARAM" == "exit_on_failure" ]; then
            report "/etc/asterisk/extensions_mor.conf or /etc/asterisk/sip.conf is missing" 1
            exit 1;
        fi
        return 1
    fi
}
#-----
configurations_test_fix()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks if all required configurations are OK

    asterisk_include_directive "/etc/asterisk/extensions_mor.conf" "extensions_mor_didww.conf"
        STATUS_1="$?"
        report "/etc/asterisk/extensions_mor.conf: #include extensions_mor_didww.conf" "$STATUS_1"

    asterisk_include_directive "/etc/asterisk/sip.conf" "sip_didww.conf"
        STATUS_2="$?"
        report "/etc/asterisk/sip.conf: #include sip_didww.conf" "$STATUS_2"

    if [ "$STATUS_1" == "4" ] || [ "$STATUS_2" == "4" ]; then
        ASTERISK_RELOAD_NEEDED=1;
    fi
}
#----------------------------
didww_was_configured_in_mor_didww_conf()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    See Internal Logic 1. for checking logic
    #
    # Returns:
    #   0   -   OK, ACCOUNTCODE was already configured
    #   1   -   FAILED, ACCOUNTCODE was not configured yet
    #
    #   Global variable $ACCOUNTCODE which holds an ACCOUNTCODE from /etc/asterisk/extensions_mor_didww.conf configuration

    ACCOUNTCODE=`sed '/^$/d' /etc/asterisk/extensions_mor_didww.conf | grep -A 2 '[from\-didww]' | grep ACCOUNTCODE | awk -F"=" '{print $3}' | awk -F")" '{print $1}'`

    if [ "$ACCOUNTCODE" == "0" ] || [ "$ACCOUNTCODE" == "" ]; then
        return 1;
    else
        return 0;        
    fi
}

check_if_device_id_matches_provided_in_providers()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function checks if device_id  in mor.providers matches ACCOUNTCODE in /etc/asterisk/extensions_mor_didww.conf 

    # Parameters:
    #   $1  - device_id to check in mor.providers
    local DEV_ID="$1"


    TMP_FILE=`/bin/mktemp`    

    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT device_id FROM providers WHERE device_id=$DEV_ID;" | (read; cat) > $TMP_FILE
    PROVIDERS_DEVICE_ID=`head -n 1 $TMP_FILE`;
    rm -rf $TMP_FILE
    
    if [ "$PROVIDERS_DEVICE_ID" == "$DEV_ID" ]; then
        return 0;
    else
        return 1;        
    fi
}
fix_extensions_mor_didww_conf()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function inserts a correct ACCOUNTCODE in /etc/asterisk/extensions_mor_didww.conf
    # Notes:    Before calling this function insert_didww_provider_into_db function must be called - it provides a global variable $DIDWW_PROVIDER_DEVICE_ID

    mkdir -p  /usr/local/mor/backups/asterisk/etc
    _mor_time;

    #backup
    cp  /etc/asterisk/extensions_mor_didww.conf /usr/local/mor/backups/asterisk/etc/extensions_mor_didww.conf_$mor_time

    # Prepare new configuration
        #remove wrong configuration
        sed "/\[from-didww\]/,/xten => _X.,2,Goto(mor,\${EXTEN},1)/d" /etc/asterisk/extensions_mor_didww.conf  > /tmp/extensions_mor_didww.conf
            
        #add correct configuration
        echo -e "[from-didww]\nexten => _X.,1,Set(CDR(ACCOUNTCODE)=$DIDWW_PROVIDER_DEVICE_ID)\nexten => _X.,2,Goto(mor,\${EXTEN},1)" >> /tmp/extensions_mor_didww.conf
            
        mv /tmp/extensions_mor_didww.conf /etc/asterisk/extensions_mor_didww.conf

        ASTERISK_RELOAD_NEEDED=1;
    #clean up
}
#----
check_if_didww_device_exists()
{
    check_if_didww_provider_exists  #getting "$DIDWW_PROVIDER_ID"
    local TMP_FILE=`/bin/mktemp`  
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT id FROM devices WHERE name='prov$DIDWW_PROVIDER_CURRENT_DEVICE_ID' LIMIT 1;" | (read; cat)  > $TMP_FILE
    DIDWW_DEVICE_ID=`cat $TMP_FILE`;
    rm -rf $TMP_FILE
}
create_didww_device()
{
    PROV_ID="$1" # here we pass provider ID
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "INSERT INTO devices(name,host,secret,context,ipaddr,port,regseconds,accountcode,callerid,extension,voicemail_active,username,device_type,user_id,primary_did_id,works_not_logged,forward_to,record,transfer,disallow,allow,deny,permit,nat,qualify,fullcontact,canreinvite,devicegroup_id,dtmfmode,callgroup,pickupgroup,fromuser,fromdomain,trustrpid,sendrpid,insecure,progressinband,videosupport,location_id,description,istrunk,cid_from_dids,pin,tell_balance,tell_time,tell_rtime_when_left,repeat_rtime_every,t38pt_udptl,regserver,ani,promiscredir,timeout,process_sipchaninfo,temporary_id,allow_duplicate_calls,call_limit,lastms,faststart,h245tunneling,latency,grace_time,recording_to_email,recording_keep,recording_email,record_forced) VALUES ('didwwwtmpprov','0.0.0.0','please_change','mor','0.0.0.0',5060,0,8,'','vtkg42rg65',0,'prov','SIP',-1,0,1,0,0,'no','all','alaw;ulaw;g729','0.0.0.0/0.0.0.0','0.0.0.0/0.0.0.0','no','yes',NULL,'no',NULL,'rfc2833',NULL,NULL,NULL,NULL,'yes','no','port,invite','never','no',1,NULL,0,0,NULL,0,0,60,60,'no',NULL,0,'no',60,0,NULL,0,0,0,'yes','yes',0,0,0,0,NULL,0);"

    #===getting newly created device ID
    local TMP_FILE=`/bin/mktemp`  
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "SELECT id FROM devices WHERE name='didwwwtmpprov' LIMIT 1;" | (read; cat)  > $TMP_FILE
    DIDWW_DEVICE_ID=`cat $TMP_FILE`;
    rm -rf $TMP_FILE
    #===updating device name
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "UPDATE devices SET name='prov$DIDWW_DEVICE_ID', accountcode=$DIDWW_DEVICE_ID WHERE name='didwwwtmpprov';"

    #===updating didww provider's device_id
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "UPDATE providers SET device_id=$DIDWW_DEVICE_ID WHERE id=$PROV_ID LIMIT 1;"     
    
}
check_if_didww_provider_exists()
{
    #   Author: Mindaugas Mardosas
    #   Year:   2011
    #   About:  This function checks if didww provider is already created
    #   
    #   Returns:
    #       0   -   OK, DIDWW provider already exists
    #       1   -   FAILED, DIDWW provider does not exist in providers table

    #   Global variables:
    #       DIDWW_PROVIDER_CURRENT_DEVICE_ID 
    #       DIDWW_PROVIDER_ID
    #       DIDWW_PROV_EXISTS {0 -ok,1-failed}

    local TMP_FILE=`/bin/mktemp`    
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e  "SELECT device_id FROM providers WHERE name='DIDWW' LIMIT 1;" | (read; cat) > $TMP_FILE
    DIDWW_PROVIDER_CURRENT_DEVICE_ID=`cat $TMP_FILE`;
    rm -rf $TMP_FILE
    if [ "$DIDWW_PROVIDER_CURRENT_DEVICE_ID" != "" ]; then
        DIDWW_PROV_EXISTS=0;
    else
        DIDWW_PROV_EXISTS=1;
        return 1;
    fi

    local TMP_FILE=`/bin/mktemp`    
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e  "SELECT id FROM providers WHERE name='DIDWW' LIMIT 1;" | (read; cat) > $TMP_FILE
    DIDWW_PROVIDER_ID=`cat $TMP_FILE`;
    rm -rf $TMP_FILE
}
#update_didww_provider_device_id()
#{
#    # Author:   Mindaugas Mardosas
#    # Company:  Kolmisoft
#    # Year:     2011
#    # About:    This function updated device_id for didww provider
#    #
#    #
#    # Returns:
#    #   0   -   OK, device_id found:
#    #               Global variable:    $DIDWW_PROVIDER_DEVICE_ID
#    #   1   -   FAILED, device_id not found
#
#    local device_id="$1" # for internal function use
#    local TMP_FILE=`/bin/mktemp`    
#   /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e  "UPDATE providers SET device_id = $device_id WHERE name='DIDWW';" 
#}
#----------------
insert_didww_provider_into_db()
{
    # Author:   Mindaugas Mardosas
    # Company:  Kolmisoft
    # Year:     2011
    # About:    This function insert a preconfigured hidden DIDWW provider
    #
    #
    # Returns:
    #   0   -   OK, device_id found:
    #               Global variable:    $DIDWW_PROVIDER_DEVICE_ID
    #   1   -   FAILED, device_id not found

    local PARAM="$1" # for internal function use

    #local TMP_FILE=`/bin/mktemp`    
    #/usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e  "SELECT device_id FROM providers WHERE name='DIDWW' LIMIT 1;" | (read; cat) > $TMP_FILE
    #DIDWW_PROVIDER_DEVICE_ID=`cat $TMP_FILE`;
    #rm -rf $TMP_FILE

    #if [ "$PARAM" != "CHECK_AGAIN" ]; then    
    #    if [ "$DIDWW_PROVIDER_DEVICE_ID" == "" ]; then    
    #    check_if_didww_device_exists
    #    if [ "$DIDWW_DEVICE_ID" == "" ]; then 
    #        create_didww_device
    #        check_if_didww_device_exists
    #        if [ "$DIDWW_DEVICE_ID" == "" ]; then 
    #            report "Failed to create a device to be used for didww provider" 1
    #            exit 1
    #        fi     
    #    fi
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "INSERT INTO providers (name, tech, channel, login, password, server_ip, port, priority, quality, tariff_id, cut_a, cut_b, add_a, add_b, device_id, ani, timeout, call_limit, interpret_noanswer_as_failed, interpret_busy_as_failed, register, reg_extension, terminator_id, reg_line, hidden, use_p_asserted_identity) VALUES ('DIDWW','SIP','','DIDWW','please_change','0.0.0.0','5060',1,1,1,0,0,'','',8,0,60,0,0,0,0,NULL,0,NULL,1,0)" 

    check_if_didww_provider_exists #getting didww provider's ID in DB
    create_didww_device "$DIDWW_PROVIDER_ID"
    check_if_didww_device_exists
    #update_didww_provider_device_id $DIDWW_DEVICE_ID
    

    if [ "$DIDWW_PROVIDER_DEVICE_ID" != "" ]; then
        return 0;
    else
        return 1;
    fi
}
#---------------MAIN-------------
asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0
fi

mysql_connect_data_v2   # retrieving MySQL connection data
mor_core_version "EXIT_IF_NO_CORE"
if [ "$MOR_CORE_BRANCH" -ge "9" ]; then  
    separator "DIDWW"
    required_cfg_exists  exit_on_failure
    configurations_test_fix
    #---------------check if didww device exist
#    check_if_didww_device_exists
#    if [ "$DIDWW_DEVICE_ID" == "" ]; then #didww device does not exist
#        create_didww_device
#        check_if_didww_device_exists
#        if [ "$DIDWW_DEVICE_ID" == "" ]; then
#            report "Failed to create a DIDWW device, bad MySQL connection details retrieved?" 1
#            exit 1
#        else
#            report "DIDWW device was added" 4
#        fi
#    fi
    #---------------check if didww provider exist
    check_if_didww_provider_exists          #checking if DIDWW provider is already added
    if [ "$DIDWW_PROV_EXISTS" == "0" ]; then    #if added
        check_if_didww_device_exists        
        if [ "$DIDWW_PROVIDER_CURRENT_DEVICE_ID" ==  "$DIDWW_DEVICE_ID" ]; then # DIDWW_DEVICE_ID is obtained earlier with  check_if_didww_device_exists
            report "DIDWW provider's device_id is OK" 0
        else
            # Čia sukuriame naują DIDWW device id
            create_didww_device "$DIDWW_PROVIDER_ID"
            check_if_didww_device_exists
            #update_didww_provider_device_id $DIDWW_DEVICE_ID
            report "Added new DIDWW device with device_id: $DIDWW_DEVICE_ID" 4
        fi
    else
        # DIDWW_DEVICE_ID is obtained earlier with  check_if_didww_device_exists
        insert_didww_provider_into_db
        check_if_didww_provider_exists 

        if [ "$DIDWW_PROVIDER_CURRENT_DEVICE_ID" ==  "$DIDWW_DEVICE_ID" ]; then
            report "DIDWW provider was added" 4
        else
            report "Failed to add a DIDWW provider. Hint check if the script correctly gets mysql db connection details" 1
        fi
    fi
    #---------------checking if didww provider and didww device are properly linked
    check_if_device_id_matches_provided_in_providers "$DIDWW_DEVICE_ID"     #checking if device id matches provided in didww provider:
    if [ "$?" == "0" ]; then
        report "DIDWW provider and didwww device are linked" 0
    else
        report "DIDWW provider and didwww device are linked" 1
        exit 1
    fi
    #---------------check if didww device id was properly specified in /etc/asterisk/extensions_mor_didww.conf
    didww_was_configured_in_mor_didww_conf 
    if [ "$ACCOUNTCODE" == "$DIDWW_DEVICE_ID" ]; then
        report "/etc/asterisk/extensions_mor_didww.conf" 0
    else
        #----- Fixing mor didww configuration file ---------------
        DIDWW_PROVIDER_DEVICE_ID=$DIDWW_DEVICE_ID
        fix_extensions_mor_didww_conf
        didww_was_configured_in_mor_didww_conf 
        if [ "$ACCOUNTCODE" == "$DIDWW_DEVICE_ID" ]; then
            report "/etc/asterisk/extensions_mor_didww.conf" 4
            report "Reloading asterisk to force it reread configurations" 3
            asterisk -vvvvvvvvvrx 'reload' &> /dev/null
        else
            report "Failed to update /etc/asterisk/extensions_mor_didww.conf" 1
            exit 1
        fi
    fi
fi
