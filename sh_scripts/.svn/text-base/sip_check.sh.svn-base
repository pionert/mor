#! /bin/bash
# @author:      Mindaugas Mardosas
# @Website:     http://www.kolmisoft.com
#this script sends a sip OPTIONS packet, writes the respond to file mentioned in FILE_TO_WRITE_OUTPUT variable and quits after 1 second.
#== VARIABLES ====
FILE_TO_WRITE_OUTPUT=/tmp/.mor_provider_check
PATH_TO_SIP_PACKET="/tmp/.mor_sip_options_packet"
#=================
#====FUNCTIONS============
prepare_packet(){  #forge'ing sip packet
        rm -rf $PATH_TO_SIP_PACKET
       
        RANDOM_NUMBER1=`< /dev/urandom tr -dc 0-9 | head -c2`;
        RANDOM_NUMBER2=`< /dev/urandom tr -dc 0-9 | head -c2`;
        RANDOM_NUMBER3=`< /dev/urandom tr -dc 0-9 | head -c2`;
        IP1="$RANDOM_NUMBER1.$RANDOM_NUMBER2.$RANDOM_NUMBER3.$RANDOM_NUMBER2";
        IP2="$RANDOM_NUMBER2.$RANDOM_NUMBER1.$RANDOM_NUMBER2.$RANDOM_NUMBER3";
        echo "OPTIONS sip:8000314@$IP1 SIP/2.0" >> $PATH_TO_SIP_PACKET
        echo "Via: SIP/2.0/UDP $IP2:5060;branch=z9hG4bK419a9da4;rport"  >> $PATH_TO_SIP_PACKET
        echo "From: \"asterisk\" <sip:asterisk@$IP2>;tag=as482045c6"    >> $PATH_TO_SIP_PACKET
        echo "To: <sip:8000314@$IP1>"   >> $PATH_TO_SIP_PACKET
        echo "Contact: <sip:asterisk@$IP2>"     >> $PATH_TO_SIP_PACKET
        echo "Call-ID: 6cac927935cd398614cfd13b1b677e2d@$IP2"   >> $PATH_TO_SIP_PACKET
        echo "CSeq: 102 OPTIONS"        >> $PATH_TO_SIP_PACKET
        echo "User-Agent: Asterisk PBX" >> $PATH_TO_SIP_PACKET
        echo 'Max-Forwards: 70' >> $PATH_TO_SIP_PACKET
        echo 'Date: Wed, 15 Jul 2009 13:08:21 GMT'      >> $PATH_TO_SIP_PACKET
        echo 'Allow: INVITE, ACK, CANCEL, OPTIONS, BYE, REFER, SUBSCRIBE, NOTIFY'       >> $PATH_TO_SIP_PACKET
        echo 'Supported: replaces'      >> $PATH_TO_SIP_PACKET
        echo 'Content-Length: 0 '       >> $PATH_TO_SIP_PACKET;
}
#==========================
which nc
if [ "$?" != "0" ]; then
        echo -e "netcat is not installed! \ntry: \napt-get install netcat \t\t\tin Debian\nyum install netcat \t\t\tin CentOS/RedHat"
fi
 
if [ "$#" == "0" ]; then 
        echo -e "No parameters passed\nUse:\n $0 host [port]\n\nIf not specified, the default port will be 5060";
        elif [ "$#" == "1" ]; then
                prepare_packet;
                nc -u -q 1 $1 5060 < "$PATH_TO_SIP_PACKET" > $FILE_TO_WRITE_OUTPUT
        elif [ "$#" == "2" ]; then
                prepare_packet;
                nc -u -q 1 $1 $2 < "$PATH_TO_SIP_PACKET" > $FILE_TO_WRITE_OUTPUT
        else 
                echo "Too much parameters"
                echo -e "Use:\n $0 host [port]\n\nIf not specified, the default port will be 5060";
fi