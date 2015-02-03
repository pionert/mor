#! /bin/bash

. /usr/src/mor/x6/framework/bash_functions.sh

VER="2.1.2"

# some magic
source "/usr/local/rvm/scripts/rvm"


if [ `rvm list | grep $VER | wc -l` = "0" ]; then

  report "Ruby $VER not present, installing..." 2
  rvm list
  ruby -v

  # rvm update
  rvm get latest
  rvm reload

  cd /usr/src/mor
  svn update

  # ruby update 
  /usr/src/mor/x6/gui/ruby_install.sh

  # for reporting to brain
  gem install rest-client

  # passenger update to newer version
  /usr/src/mor/x6/gui/passenger_install.sh


  source "/usr/local/rvm/scripts/rvm" &> /dev/null
  rvm use 2.1.2

  # x6 fix for node
  if [ -d "/home/x6" ]; then
    report "Upgrading gems for X6" 3
    cd /home/x6
    svn update
    bundle update
    report "Gems for X6 upgraded" 0
  fi

  # m2 fix
  if [ -d "/home/m2" ]; then
    report "Upgrading gems for M2" 3
    cd /home/m2
    svn update
    bundle update
    report "Gems for M2 upgraded" 0
  else

    # mor fix generic
    if [ -d "/home/mor" ]; then

      cd /home/mor

	if [ "$1" == "STABLE" ]; then
	    stable_rev=`cat /usr/src/mor/x6/stable_revision`
	    report "Upgrading /home/mor from svn to STABLE revision: $stable_rev" 3
	    svn -r $stable_rev update &> /dev/null
	else
	    report "Upgrading /home/mor from svn to LATEST revision" 3
	    svn update &> /dev/null
	fi

      report "Upgrading gems for MOR" 3
      bundle update
      report "Gems for MOR upgraded" 0
    fi

  fi

  /etc/init.d/httpd restart

  if [ `rvm list | grep $VER | wc -l` = "0" ]; then
    report "Something bad happened, Ruby $VER not installed, contact MK" 1
    ruby -v
    rvm list
  else
    report "Ruby $VER installed" 0
  fi

else

  report "Ruby $VER present" 0

  rvm use 2.1.2

fi
