#! /bin/sh
#
#   Author: Mindaugas Mardosas
#   Year:   2012
#   About:  This script fixes UTF-8 problems when migrating <MOR12 to MOR12 with ROR3
#
#   Important: This script must be run when you are sure that 1.8.7 or 1.8.5 ruby is present system wide (accessible when running directly /usr/bin/ruby) or RVM is installed and activated
#

. /usr/src/mor/test/framework/bash_functions.sh

. /usr/src/mor/sh_scripts/mor_install_functions.sh

#------------Functions------------------------

check_if_fix_is_needed()
{
    #   Author: Mindaugas   Mardosas
    #   Year:   2012
    #   About:  This function checks if DB UTF-8 fix was already applied
    #
    #   Returns
    #       1   -   FAILED, we need to apply fix
    #       0   -   OK, DB is already fixed

    TMP_FILE=`/bin/mktemp`
    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" -e "DESC payments" | (read; cat) > $TMP_FILE
    FIX_NEEDED=`cat $TMP_FILE | grep blob | wc -l`;
    if [ "$FIX_NEEDED" != "0" ]; then
        return 1
    else
        return 0
    fi    
}

prepare_ruby_187()
{
    #   Author: Mindaugas   Mardosas
    #   Year:   2012
    #   About:  Ruby script MUST be run from ruby 1.8.7 , this function takes care of preparing/installing ruby 1.8.7
    #
    #   Returns:
    #       0   -   system ruby will be ok for this task
    #       1   -   something failed
    #       2   -   use 1.8.7 ruby via rvm for completing this task
    
    if [ -f /usr/bin/ruby ] && [ `/usr/bin/ruby -v | grep "1.8.5\|1.8.7" | wc -l` == 1 ]; then
        report "Ruby 1.8.5 or 1.8.7 found" 0
        return 0
    else # Required ruby version not found. We will have to install one ourselves
        
        if [ `rvm list | grep "1.8.7" | wc -l` != 0 ]; then # checking maybe we have it installed via rvm already?
            return 2
        else
                
            report "We need old ruby 1.8.7 to upgrade your database to add UTF-8 support. Sit back and wait till we install it for temporary usage... This can take up to ~10 min depending on you internet and processor speed" 3
            rvm install 1.8.7
            
            rvm ruby-1.8.7 do rvm gemset create 187
                    
            mkdir -p /usr/src/gems
            cd /usr/src/gems
            wget -c http://www.kolmisoft.com/packets/gems/1.8.6.tar.gz
            tar xzvf 1.8.6.tar.gz
            cd 1.8.6
            
            rvm ruby-1.8.7@187 do gem install hoe -v=2.3.3 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install actionmailer -v=1.3.6 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install actionpack -v=1.13.6 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install actionwebservice -v=1.2.6 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install activerecord -v=1.15.6 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install activesupport -v=1.4.4 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install archive-tar-minitar -v=0.5.2 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install builder -v=2.1.2 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install color -v=1.4.0 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install fcgi -v=0.8.7 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install ferret -v=0.11.6 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install hoe -v=2.3.3 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install mime-types -v=1.16 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install mysql -v=2.7 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install pdf-wrapper -v=0.1.0 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install pdf-writer -v=1.1.8 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install rails -v=1.2.6 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install rake -v=0.8.7 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install rest-client -v=1.6.1 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install rubyforge -v=1.0.4 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install Selenium -v=1.1.14 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install sources -v=0.0.1 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install transaction-simple -v=1.4.0 --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install passenger --no-rdoc --no-ri
            rvm ruby-1.8.7@187 do gem install mysql -v 2.8.1 --no-rdoc --no-ri
            
            return 2
        fi
    fi
}
#------------------ MAIN ----------

mysql_connect_data_v2      > /dev/null
check_if_fix_is_needed
if [ "$FIX_NEEDED" == "1" ]; then
    if [ ! -f /usr/src/mor/upgrade/12/utf_fix.rb ]; then
        report "Fix script is not installed and is not available. Update /usr/src/mor and try again" 1
        exit 1
    fi
    
    prepare_ruby_187
    STATUS="$?"
    
    if [ "$STATUS" == "0" ]; then   # System ruby is OK for this task
       RUBY_PATH_PREFIX="rvm system do ruby "
    elif [ "$STATUS" == "2" ]; then # Installed ruby via rvm for this task
        RUBY_PATH_PREFIX="rvm ruby-1.8.7@187 do ruby"
    else
        report "Failed to update your database to support UTF-8" 1
        exit 1
    fi
    
    # Launching ruby magic with required ruby version to fix database. More information about this magic can be found here: http://trac.kolmisoft.com/trac/ticket/6607
    tmp_file=`/bin/mktemp`
    $RUBY_PATH_PREFIX /usr/src/mor/upgrade/12/utf_fix.rb -s "$DB_HOST" -u "$DB_USERNAME"  -p "$DB_PASSWORD" -n "$DB_NAME" &> $tmp_file
    FILE=`awk '{print $3}' $tmp_file`

    /usr/bin/mysql -h "$DB_HOST" -u $DB_USERNAME --password=$DB_PASSWORD "$DB_NAME" < $FILE

    rm -rf $FILE $tmp_file  #cleanup
fi
