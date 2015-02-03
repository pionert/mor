#! /bin/bash

environment_rb_update()
{
   RSACTIVE=`cat /home/mor/config/environment.rb | grep -i "RS_Active"`;
   C2CACTIVE=`cat /home/mor/config/environment.rb | grep -i "C2C_Active"`;

   if [ "$RSACTIVE" == "" ]; then echo -e "\nRS_Active = 0" >> /home/mor/config/environment.rb; fi
   if [ "$C2CACTIVE" == "" ]; then echo -e "\nC2C_Active = 0" >> /home/mor/config/environment.rb; fi
    
    echo "environment.rb updated"
}


#cat home/mor/config/environmet.rb


mor_conf_update()
{
   ZAP_CHANGE=`grep -i "zap_change" /etc/asterisk/mor.conf`
   if [ "$ZAP_CHANGE" == "" ]; then echo -e "\n;zap technology change\n;zap_change = zap" >> /etc/asterisk/mor.conf; fi

   SRV_ID=`grep -i "server_id" /etc/asterisk/mor.conf`
   if [ "$SRV_ID" == "" ]; then echo -e "\n; unique number for server identification\nserver_id=1" >> /etc/asterisk/mor.conf; fi

   ACT_CALLS=`grep -i "active_calls" /etc/asterisk/mor.conf`
   if [ "$ACT_CALLS" == "" ]; then echo -e "\n; should we add/update/delete active calls to/from DB?\n; This option is necessary for call-limit support\nactive_calls=1" >> /etc/asterisk/mor.conf; fi

   DIAL_OUT_SET=`grep -i "dial_out_settings" /etc/asterisk/mor.conf`
   if [ "$DIAL_OUT_SET" == "" ]; then echo -e "\n; Dial command settings for dialing out (using providers)\ndial_out_settings =  " >> /etc/asterisk/mor.conf; fi

    echo "mor.conf updated"

}


environment_rb_update;

mor_conf_update;