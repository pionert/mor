#! /bin/bash
        : ${VERBOSE:="0"}       #additional info on/off
                #======================
                        replace_line_in_file()          #can be deleted when mor_install_functions will be updated (2009 02 28)
                        {  #1 arg - file to modify
                                #2 arg - what to replace
                                #3 arg - replace with
                                #4 arg must be 1, if backup is needed
                                #exemple: replace_line_in_file /tmp/somefile foo bar 1
                                 
                                cat $1 | sed "s/$2/$3/" > /tmp/replace_line$$;
                                if [ $4 == 1 ]; then mv $1 $1_back$$; fi
                                mv /tmp/replace_line$$ $1
                        }
                        #=============
                        mor_determine_server_ip()               #can be deleted when mor_install_functions will be updated  (2009 02 28)
                        {       
                                #finds server ip
                                MOR_SRV_IP=`ifconfig | awk '/inet addr:/ {print $2}' | awk '{split ($0,a,":"); print a[2]}' | awk '{split ($0,a,"127."); print a[1]}'`;
                                if [ -z "$MOR_SRV_IP" ]; then
                                        echo "IP resolve failed";
                                        exit 1;
                                fi
                                return 0;
                        }
                        #================
#===================MAIN===============================
mor_determine_server_ip
[ "$VERBOSE" == "1" ] && echo "$MOR_SRV_IP";
if [ -n "$MOR_SRV_IP" ];
        then   
                        replace_line_in_file "/etc/asterisk/h323.conf" ";bindaddr = 1.2.3.4" "bindaddr = $MOR_SRV_IP" 1
        else   
                        echo "Server IP resolve failed in mor_determine_server_ip function"
                        exit 1;
fi
