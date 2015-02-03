#! /bin/sh

TMP_FILENAME=`date +%H%M%S%N`

#echo $TMP_FILENAME
while read line; 
do echo "${line}" >> /tmp/$TMP_FILENAME; 
done


subject=`cat /tmp/$TMP_FILENAME | grep 'Subject: ' | awk '{split ($0,a," "); print a[2]}'`
param1=`cat /tmp/$TMP_FILENAME | grep 'MOR_PARAM1 ' | awk '{split ($0,a," "); print a[2]}'`
param2=`cat /tmp/$TMP_FILENAME | grep 'MOR_PARAM2 ' | awk '{split ($0,a," "); print a[2]}'`
param3=`cat /tmp/$TMP_FILENAME | grep 'MOR_PARAM3 ' | awk '{split ($0,a," "); print a[2]}'`

wget -o /dev/null -O /dev/null "http://localhost/billing/emails/email_callback?subject=$subject&param1=$param1&param2=$param2&param3=$param3"

echo ""  >> /tmp/mor_email_callback.log
echo $TMP_FILENAME >> /tmp/mor_email_callback.log
echo $subject >> /tmp/mor_email_callback.log
echo $param1 >> /tmp/mor_email_callback.log
echo $param2 >> /tmp/mor_email_callback.log
echo $param3 >> /tmp/mor_email_callback.log

#echo "wget -o /dev/null -O /dev/null http://localhost/billing/emails/email_callback?subject=$subject&param1=$param1&param2=$param2&param3=$param3"  >> /tmp/mor_email_callback.log