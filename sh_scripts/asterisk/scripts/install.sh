#!/bin/sh

#ivr script
/bin/cp -fr /usr/src/mor/sh_scripts/asterisk/scripts/mor_ast_generate_ivr.c /usr/src/mor/scripts/
cd /usr/src/mor/scripts
./install.sh


#auto dialer fix
/bin/cp -fr /usr/src/mor/sh_scripts/asterisk/scripts/cagi.c /home/mor_ad/agi/
cd /home/mor_ad/agi
./install.sh

