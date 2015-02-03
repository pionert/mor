#! /bin/sh
# Year: 2010
# Company: http://www.kolmisoft.com

NEEDED_GEM_VERSION="1.3.5";                  #set this to required Ruby Gem versio
URL="www.kolmisoft.com/packets";             #set this to repository address
CURRENT_GEM_VERSION=`gem -v`;

if [ "$NEEDED_GEM_VERSION" != "$CURRENT_GEM_VERSION" ]; then
    echo "Ruby GEM versions mismatched, downloading and installing the required version from Kolmisoft";
    cd /usr/src/
    wget http://$URL/rubygems-$NEEDED_GEM_VERSION.tgz
    tar xzvf rubygems-1.3.5.tgz
    cd rubygems-$NEEDED_GEM_VERSION
    ruby setup.rb
    if [ "$?" == "0" ]; then
        echo -e "Ruby GEM installation was successfull\nRestarting Apache webserver";
        /etc/init.d/httpd restart;
        exit 0;
    else
        echo "Failed to install Ruby GEM from Kolmisoft"
        exit 1;
    fi
fi
echo "Your system has the correct Ruby gem version: $CURRENT_GEM_VERSION";
