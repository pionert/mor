#! /bin/sh

# TRAC 10962
# Previuosly by mistake '#' was added instead of ';' 
# So now we change 'console=...' to ';console' or '#console' to ';console'

. /usr/src/mor/x6/framework/bash_functions.sh

check_console_alias()
{
    local config="/etc/asterisk/cli_aliases.conf"

    if grep -E -q '^#?console=console' $config; then
        sed -i 's/^#\?console=console/\;console=console/' $config
        
        if grep -q '^;console=console' $config; then
           report "Commented-out 'console=console' line in $config" 4
           report "Asterisk restart is needed" 6
        else
           report "Failed to comment (add ;)  'console=console' line in $config" 1
           report "Check $config file and TRAC 10962" 1
        fi
    else
        report "'console=console' is already commented out in $config" 0
    fi
  
}
    
asterisk_is_running

if [ "$?" != "0" ]; then
    exit 0
fi

check_console_alias