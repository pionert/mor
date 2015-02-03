#! /bin/bash

# prepare files/folders
touch /usr/local/mor/test_environment/last_revision_x6
touch /var/log/mor/failed_tests_x6

# prepare GUI
svn co http://svn.kolmisoft.com/mor/gui/branches/x6 /home/x6
cp -fr /home/x5/config/database.yml /home/x6/config/
cp -fr /home/x5/config/environment.rb /home/x6/config/
mkdir -p /home/x6/tmp
chmod 777 /home/x6/tmp
mkdir -p /home/mor/public/ivr_voices
chmod 777 /home/mor/public/ivr_voices
chmod 755 /home/mor/public
chmod +t /home/mor/public

# make symlink
rm -fr /usr/local/mor/test_environment/mor_test_run.sh
ln -s /usr/src/mor/test/cluster1/x6/mor_test_run.sh /usr/local/mor/test_environment/mor_test_run.sh

# bundles
cd /home/x6
bundle update

/etc/init.d/httpd restart
