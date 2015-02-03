#! /bin/sh

# includes
. /usr/src/mor/x6/framework/framework.conf
. /usr/src/mor/x6/framework/mor_install_functions.sh
. /usr/src/mor/x6/framework/bash_functions.sh


mkdir -p /var/lib/asterisk/sounds/mor
if [ ! -d "/home/mor/public/ivr_voices" ]; then
    #if folder does not exist, lets create it. This indicates fresh install
    mkdir -p /home/mor/public/ivr_voices
    ln -s /home/mor/public/ivr_voices /var/lib/asterisk/sounds/mor/ivr_voices &> /dev/null
else
    #if folder exist that just check if symlic is ok and make copies to create end_ivr files by using existing one. This indicates Update/Upgrade
    ln -s /home/mor/public/ivr_voices /var/lib/asterisk/sounds/mor/ivr_voices &> /dev/null

    end_ivr_new_files="ani_end_ivr_1 ani_end_ivr_2 cc_end_ivr_1 cc_end_ivr_4 cc_end_ivr_5 cc_end_ivr_6 "
    end_ivr_new_files_array=($end_ivr_new_files)
    sound_language_directories=`ls -l /var/lib/asterisk/sounds/mor/ivr_voices/ | grep "^d" | awk '{print $9}' | awk '{printf "%s " ,$1}'`
    sound_language_directories_array=($sound_language_directories)
    for dir_element in $(seq 0 $((${#sound_language_directories_array[@]} - 1)))
    do
        if [ -f "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/cc_callingcard_choices.wav" ]; then
            for file_element in $(seq 0 $((${#end_ivr_new_files_array[@]} - 1)))
            do
                if [ ! -f "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/${end_ivr_new_files_array[$file_element]}.wav" ]; then
                    cp "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/cc_callingcard_choices.wav" "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/${end_ivr_new_files_array[$file_element]}.wav"
                fi
            done
        fi
        if [ -f "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/cc_please_enter_number.wav" ] && [ ! -f "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/cc_end_ivr_2.wav" ]; then
            cp "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/cc_please_enter_number.wav" "/var/lib/asterisk/sounds/mor/ivr_voices/${sound_language_directories_array[$dir_element]}/cc_end_ivr_2.wav"
        fi
    done
fi

#does not matter if it was fresh install or update/upgrade lets check permissions and download missing files
report "Dowloading sound files" 3
find /home/mor/public/ivr_voices/ -name "index.html*" -type f -delete
wget -r -nc --no-parent --recursive -nH --cut-dirs=4  http://www.kolmisoft.com/packets/x5_sounds/mor/ivr_voices/ -P /home/mor/public/ivr_voices/ &> /dev/null
find /home/mor/public/ivr_voices/ -name "index.html*" -type f -delete
mkdir -p /var/lib/asterisk/sounds/digits
find /var/lib/asterisk/sounds/digits/ -name "index.html*" -type f -delete
wget -r -nc --no-parent --recursive -nH --cut-dirs=3  http://www.kolmisoft.com/packets/x5_sounds/digits/ -P /var/lib/asterisk/sounds/digits/ &> /dev/null
find /var/lib/asterisk/sounds/digits/ -name "index.html*" -type f -delete

#this one should be located in non-standard directory
cd /var/lib/asterisk/sounds/mor/
wget -c http://www.kolmisoft.com/packets/x5_sounds/mor/mor_pls_wait_connect_call.gsm

# ivr fix permissions
chmod 777 /home/mor/public
chmod 777 /home/mor/public/ivr_voices
chmod 777 -R /home/mor/public/ivr_voices
chmod 777 /var/lib/asterisk/sounds/mor/
chmod 777 /var/lib/asterisk/sounds/
chmod 777 /var/lib/asterisk/
chmod 777 /var/lib/
chmod 777 /var/
chown -R apache: /home/mor/public/ivr_voices


# silence files
#mkdir -p /var/lib/asterisk/sounds/mor/ivr_voices/silence
#cp -fr /usr/src/mor/sounds/silence/* /var/lib/asterisk/sounds/mor/ivr_voices/silence
#chmod -R 777 /home/mor/public/ivr_voices/silence

report "Sound files downloaded" 0