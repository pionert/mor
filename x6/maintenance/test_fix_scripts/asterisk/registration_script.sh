#! /bin/sh

. /usr/src/mor/x6/framework/bash_functions.sh

#----------------------------
registration_script_test()
{
   if [ -r /usr/local/mor/mor_ast_register ];
      then return 0;
      else return 1;
   fi
}
#----------------------------

asterisk_is_running
if [ "$?" != "0" ]; then
    exit 0
fi

registration_script_test
if [ "$?" == "0" ]; then
    report "Asterisk registration script mor_ast_register" 0
    exit 0
else
    report "Asterisk registration script mor_ast_register" 1
    exit 1
fi
