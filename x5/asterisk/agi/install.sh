#!/bin/sh

. /usr/src/mor/x5/framework/bash_functions.sh

report "AGI scripts install started, please hold..." 3

cd /usr/src/mor/x5/asterisk/agi

# mor_acc2user

rm -fr mor_acc2user &> /dev/null
gcc -I/usr/include/mysql mor_acc2user.c -o mor_acc2user -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_acc2user /var/lib/asterisk/agi-bin


# mor_tellbalance

rm -fr mor_tellbalance &> /dev/null
gcc -I/usr/include/mysql mor_tellbalance.c -o mor_tellbalance -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_tellbalance /var/lib/asterisk/agi-bin


# mor_usevoucher

rm -fr mor_usevoucher &> /dev/null
gcc -I/usr/include/mysql mor_usevoucher.c -o mor_usevoucher -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_usevoucher /var/lib/asterisk/agi-bin


# mor_mnp

rm -fr mor_mnp &> /dev/null
gcc -I/usr/include/mysql mor_mnp.c -o mor_mnp -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_mnp /var/lib/asterisk/agi-bin


# mor_cc_external

rm -fr mor_cc_external &> /dev/null
gcc -I/usr/include/mysql mor_cc_external.c -o mor_cc_external -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_cc_external /var/lib/asterisk/agi-bin

# mor_answer_mark

rm -fr mor_answer_mark &> /dev/null
gcc -I/usr/include/mysql mor_answer_mark.c -o mor_answer_mark -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_answer_mark /var/lib/asterisk/agi-bin

# mor_callback

rm -fr mor_callback &> /dev/null
gcc -I/usr/include/mysql mor_callback.c -o mor_callback -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_callback /var/lib/asterisk/agi-bin

# mor_card_topup

rm -fr mor_card_topup &> /dev/null
gcc -I/usr/include/mysql mor_card_topup.c -o mor_card_topup -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_card_topup /var/lib/asterisk/agi-bin

# mor_action_log

rm -fr mor_action_log &> /dev/null
gcc -I/usr/include/mysql mor_action_log.c -o mor_action_log -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_action_log /var/lib/asterisk/agi-bin

# mor_play_random

rm -fr mor_play_random &> /dev/null
gcc -I/usr/include/mysql mor_play_random.c -o mor_play_random -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_play_random /var/lib/asterisk/agi-bin

# mor_pinless_control

rm -fr mor_pinless_control &> /dev/null
gcc -I/usr/include/mysql mor_pinless_control.c -o mor_pinless_control -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_pinless_control /var/lib/asterisk/agi-bin

# mor_fax2email
rm mor_fax2email &> /dev/null
gcc -I/usr/include/mysql mor_fax2email.c -o mor_fax2email -L/usr/lib/mysql -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_fax2email /var/lib/asterisk/agi-bin

# mor_ad_agi
rm mor_ad_agi &> /dev/null
gcc -I/usr/include/mysql mor_ad_agi.c -o mor_ad_agi -lmysqlclient -lnsl -lm -lz -L/usr/lib/mysql -L/usr/lib/mysql -L/usr/lib64/mysql
cp -fr mor_ad_agi /var/lib/asterisk/agi-bin

report "AGI scripts install completed" 0
