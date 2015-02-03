#! /bin/sh

# Author:   Ričardas Stoma
# Company:  Kolmisoft
# Year:     2013
# About:    Script configures asterisk dialplan for queues

FILE_MOH=/etc/asterisk/musiconhold.conf
FILE_QUEUES=/etc/asterisk/queues.conf
FILE_EXTENSIONS_QUEUES=/etc/asterisk/extensions_mor_queues.conf

# create musiconhold.conf if not exists
if [ ! -f $FILE_MOH ]; then
    touch $FILE_MOH
fi

# check if musiconhold.conf is configured correctly
grep 'mor_musiconhold' $FILE_MOH &> /dev/null
if [ $? -eq 1 ]; then
    echo "#exec /usr/local/mor/mor_musiconhold" >> $FILE_MOH
fi

# create queues.conf if not exists
if [ ! -f $FILE_QUEUES ]; then
    touch $FILE_QUEUES
fi

# check if queues.conf is configured correctly
grep 'mor_queues' $FILE_QUEUES &> /dev/null
if [ $? -eq 1 ]; then
    echo "#exec /usr/local/mor/mor_queues" >> $FILE_QUEUES
fi

# create extensions_mor_queues.conf if not exists
if [ ! -f $FILE_EXTENSIONS_QUEUES ]; then
    touch $FILE_EXTENSIONS_QUEUES
fi

# check if extensions_mor_queues.conf is configured correctly
grep 'mor_extensions_queues' $FILE_EXTENSIONS_QUEUES &> /dev/null
if [ $? -eq 1 ]; then
    echo "#exec /usr/local/mor/mor_extensions_queues" >> $FILE_EXTENSIONS_QUEUES
fi
