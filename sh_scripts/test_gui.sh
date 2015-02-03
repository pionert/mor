#!/bin/sh

cd /usr/src/mor/sh_scripts
. mor_install_functions.sh

clear

echo ""
echo "Populating TEST database, please wait...."
echo ""

#cd /home/mor
#rake db:test:clone


mysql_connect_data

mysqldump -h $HOST -u $DB_USERNAME -p$DB_PASSWORD $DATABASE | mysql -u $DB_USERNAME -p$DB_PASSWORD mor_test
/usr/bin/mysql -h $HOST -u $DB_USERNAME --password=$DB_PASSWORD mor_test -e "UPDATE users SET id = 0 WHERE username = 'admin';"

if [ -r /tmp/mor_gui_test.log ]; then
    rm /tmp/mor_gui_test.log
fi

FILES=`ls /home/mor/test/functional`

#cd /home/mor

for f in $FILES
do
    
    echo "Processing $f file..."
    
    ruby /home/mor/test/functional/$f -n /after_install/ >> /tmp/mor_gui_test.log
    echo "---------------" >> /tmp/mor_gui_test.log
	    
	    
done

#ruby test/functional/accounting_controller_test.rb -n /after_install/ >> /tmp/mor_gui_test.log
#echo "---------------" >> /tmp/mor_gui_test.log

#ruby test/functional/services_controller_test.rb -n /after_install/ >> /tmp/mor_gui_test.log
#echo "---------------" >> /tmp/mor_gui_test.log

#ruby test/functional/payments_controller_test.rb -n /after_install/ >> /tmp/mor_gui_test.log
#echo "---------------" >> /tmp/mor_gui_test.log

clear

cat /tmp/mor_gui_test.log #| grep "failures|Loaded"

echo ""

cat /tmp/mor_gui_test.log | egrep "failures|Loaded"


rm /tmp/mor_gui_test.log

chmod 777 /tmp/*

echo ""
echo "Press ENTER to exit"

read;
