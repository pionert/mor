#!/bin/sh


echo "Will generate $1 call(s)"

if [ $1 -gt 0 ]; then

    for ((i=0;i<$1;i+=1)); do
	echo $i
	
	FILENAME=`date +%H%M%S%N`
	
	cp callfile /var/spool/asterisk/outgoing/$FILENAME
	
    done

fi
