#! /usr/bin/python
#   Author: Mindaugas Mardosas
#   Year:   2013
#   About:  This script parses log /var/log/asterisk/messages file and parses it to CSV which can be imported in MOR system.
#
#   Usage: /usr/src/mor/sh_scripts/cdr_extractor.py /var/log/asterisk/messages | grep FAILED
#
#   You will get unique call ids for FAILED to extract call on your screenr
#
#
#   Successfully extracted CDRs can be found here: /tmp/CDR_recovered_from_messages_log.csv
#   

import re
import sys
import string
import csv
import os
from datetime import datetime, timedelta

file = open(sys.argv[1], "r")

DEBUG = False



keys = list()   # For storing time, call ID and uniqueid
text_list = list()




with open('/tmp/CDR_recovered_from_messages_log.csv', 'w') as csvfile:
    cdr = csv.writer(csvfile, delimiter=';',  quotechar="'", quoting=csv.QUOTE_MINIMAL)
    cdr.writerow(['calldate', 'provider_id', 'clid', 'uniqueid', 'dst', 'src', 'real_billsec', 'user_id', 'real_duration', 'reseller_id'])                    

    #==== GREPING A LIST OF LINES WHICH ARE IMPORTANT FOR US ===================
    
    for line in file:
        if re.search('uniqueid', line) and not re.search('Duplicate', line):
            list_splitted = line.translate(None, "[]").replace('NOTICE', '').split(' ')
            
            time_prepared="%s:%s" % (list_splitted[1].split(':')[0], list_splitted[1].split(':')[1])
            
            CLID=line.split('CLID: ')[1].split(',')[0]
            SRC=line.split('Src: ')[1].split(',')[0]
            DST=line.split('Dst: ')[1].split(',')[0]
            UNIQUE_CALL_ID=line.split('uniqueid: ')[1].split(',')[0]

            keys.append([UNIQUE_CALL_ID, list_splitted[2], list_splitted[0],  time_prepared, CLID, SRC, DST])
            continue
            
        line_filtered = line.translate(None, "[]").replace('NOTICE', '')
        
        if re.search('app_mor.c: Hangupcause:', line_filtered):
            text_list.append(line_filtered )
            continue
        
        if re.search('Real Duration', line_filtered):
            text_list.append(line_filtered )
            continue
        
        if re.search('prov_id', line_filtered):
            text_list.append(line_filtered )
            continue
            
        if re.search('Terminator', line_filtered):
            text_list.append(line_filtered )

        if re.search("User's data retrieved", line_filtered):
            text_list.append(line_filtered )

            
        del line_filtered
    
    #=================================================
    
    
    #--- Finding all terminators
    terminators = dict()
    print 'Building terminators list'
    for t in text_list:
        #[2013-08-14 01:21:16] NOTICE[29996] app_mor_callingdata.c:  prov_id: 14, SIP/  @ 216.53.4.1, device_id: 165, prefix: 5144, rate: 0.008500000000000, increment: 1, min_time: 0, conn_fee: 0.000000, exchange rate: 1.000000, cut: , add: 99902, timeout: 60, interpret as failed: no answer: 1, busy: 1, priority: 2, call limit: 0, active calls: 0, latency: 0.000000, grace_time: 0, percent: 0, fake_ring: 0, save_call_log: -735392056, use pai: 0, 302 support: 0, common use: 0, owner_id: 0, time_limit_per_day: 0, max_timeout: 0, user_id: -1
        if re.search('  prov_id: ', t):
            TERMINATOR_IP = t.split('@')[1].split(',')[0].replace(' ', '')
            PROVIDER_ID = t.split('prov_id: ')[1].split(',')[0]
            if TERMINATOR_IP not in terminators.keys():
                terminators[TERMINATOR_IP] = PROVIDER_ID


    if DEBUG:
        print 'Found these terminators'
        print terminators.keys()
        print 'Building terminators list finished'
    
    
    LAST_KEY=None
    
    print 'Date; CLID; Source; DST; Billsec; Provider ID; UNIQUE CALL ID'
    for k in keys:
        
        if LAST_KEY:
            print '[FAILED] %s' % str(LAST_KEY)
    
        LAST_KEY=k
    
        
        if DEBUG:
            print 'Unique call id: %s ' % k[0]
        #print k
        key_time = datetime.strptime("%s %s" % (k[2], k[3]), '%Y-%m-%d %H:%M')
        #print key_time
        
        other_time_limit = key_time + timedelta(hours = 1) # key_time + 1 hour
        DATE_AND_TIME=key_time
        
        if DEBUG:
            print '\n\n--------\nKey time: %s' % key_time.strftime('%Y-%m-%d %H:%M')
            print 'Searching till: %s\n\n----' % other_time_limit.strftime('%Y-%m-%d %H:%M')
                        
        CLID=None
        Source=None
        DST=None
        Billsec=None
        Real_duration=None
        Provider_id=None
        User_id=None
        Reseller_id=None

        tmp_terminator = None
        #------------
    
        for t in text_list: # we traverse all text
    
            if re.search(k[1], t):  # if call id is ok
                list_splitted = t.translate(None, "[]").replace('NOTICE', '').split(' ')
     
                time_prepared="%s:%s" % (list_splitted[1].split(':')[0], list_splitted[1].split(':')[1])            
                t_time = datetime.strptime("%s %s" % (list_splitted[0], time_prepared), '%Y-%m-%d %H:%M')
                    
                if re.search('Terminator IP', t): #PROV_ID:
                    TERMINATOR_IP = t.split(' ')[-1].split('\n')[0]
                    Provider_id = terminators[TERMINATOR_IP]
                    tmp_terminator = TERMINATOR_IP

                # User ID
                if re.search("User's data retrieved", t): # User ID
                    User_id = t.split(' id: ')[1].split(',')[0]
                    Reseller_id = t.split("owner: ")[1].split(',')[0]

                    

                #Billsec
                if re.search('Real Billsec', t):
                    if DEBUG:
                        print 'Found real billsec: %s' % t
                    Billsec = t.split(',')[3].split(':')[1].replace(' ', '')
                    CLID=k[4]
                    Source=k[5]
                    DST=k[6]
                    Real_duration = t.split('Real Duration:')[1].split(',')[0].strip()

    
                # Printing
                if Billsec != None and Provider_id != None:
                    #print [key_time.strftime('%Y-%m-%d %H:%M'), CLID,  Source, DST, Billsec.replace('\n', ''), Provider_id, k[0]]
                    #cdr.writerow([key_time.strftime('%Y-%m-%d %H:%M'), CLID,  Source, DST, Billsec.replace('\n', ''), Provider_id, k[0]])

                    # Writing to CDR                    
                    cdr.writerow([key_time.strftime('%Y-%m-%d %H:%M'), Provider_id, CLID, k[0], DST, Source, Billsec.replace('\n', ''), User_id, Real_duration, Reseller_id] )

                    LAST_KEY=None
                    break   #found everything for this call
                
                if re.search('Hangupcause: FAILED', t):   # Unauthenticated call, has to be skipped
                    LAST_KEY = None
                    break
