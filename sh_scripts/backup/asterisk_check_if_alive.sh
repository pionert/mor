#! /bin/bash

# returns 0 if asterisk server is alive
# returns 1 if asterisk server is dead

#====================================
# execution: /bin/sh  /your_path/asterisk_check_if_alive.sh arg1 arg2 arg3 and etc...
#  arg1 ssh_username
#  arg2 server_ip
#  arg3 ssh_port
#  arg4 ssh_pass
#====================================


expect -c spawn ssh '$1'@'$2' -p'$3' "asterisk -vvvrx \"show channels\" | grep Connected"; expect password ; send "'$4'\n" ; interact' > /tmp/ast_check && cat /tmp/ast_check | grep  "Connected to Asterisk*" > /tmp/ast_check2

IS_AST_ALIVE=`cat /tmp/ast_check2 `;


if [ -n "$IS_AST_ALIVE" ]; 
then echo 0;
else 
   echo 1;	
fi;

unset IS_AST_ALIVE
rm -rf /tmp/ast_check /tmp/ast_check2
