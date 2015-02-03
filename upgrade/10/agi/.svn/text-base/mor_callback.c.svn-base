/*
*
*	MOR Callback Activation AGI script
*	Copyright Mindaugas Kezys / Kolmisoft 2007-2009
*
*	v0.1.5
*
*	2010-10-12   v0.1.5  Pass MOR_DP_ID, MOR_CC_DID, bugfix to callback
*       2009-12-11   v0.1.4  CallerID support
*       2009-07-09   v0.1.3  RetryTime 120s
*       2009-06-17   v0.1.2  WaitTime 120s
*       2009-06-02   v0.1.1  Calling Card support
*
*/


#include <stdio.h>
#include <stdarg.h>
//#include <mysql.h>
#include <time.h> 

#include "cagi.c"


#define TOUCH_TIME_FORMAT "%Y%m%d%H%M.%S" 




/*	Variables	*/

//callback vars
char source[50] = "";
char uid[50] = "";
char did[50] = "";
int wait_time;
char device_id[20] = "";
char card_id[50] = "";
char callerid[50] = "";

char dp_id[20] = "";
char cc_did[20] = "";

AGI_TOOLS agi;
AGI_CMD_RESULT res;



/*	Main function	*/

int main(int argc, char *argv[])
{
//	char dest[100];
	char str[1024];
	char buff[1024];    
	char systcmd[256]; 

	time_t time_now = time(NULL);
	long int execute_time;

	// call file vars
	FILE *cfile;
	char callfile[2048]; 
        char fname[128], temp_file[128], spool_file[128]; 
	
	char touch_time[64];
	struct tm tm;
	time_t t1; 



	AGITool_Init(&agi);

	AGITool_verbose(&agi, &res, "", 0);
	AGITool_verbose(&agi, &res, "MOR Callback Activation AGI script started.", 0);

	strcpy(source, AGITool_ListGetVal(agi.agi_vars, "agi_extension")); 

	AGITool_get_variable2(&agi, &res, "MOR_CB_UID", uid, sizeof(uid));

	AGITool_get_variable2(&agi, &res, "MOR_CB_DID", did, sizeof(did));

	AGITool_get_variable2(&agi, &res, "MOR_CB_WAIT_TIME", buff, sizeof(buff));
	wait_time = atoi(buff);

	AGITool_get_variable2(&agi, &res, "MOR_CB_DEVICE_ID", device_id, sizeof(device_id));
	
	AGITool_get_variable2(&agi, &res, "MOR_CARD_ID", card_id, sizeof(card_id));	

	AGITool_get_variable2(&agi, &res, "MOR_CB_CALLERID", callerid, sizeof(callerid));	

        AGITool_get_variable2(&agi, &res, "MOR_DP_ID", dp_id, sizeof(dp_id));   

        AGITool_get_variable2(&agi, &res, "MOR_CC_DID", cc_did, sizeof(cc_did));        


	execute_time = time_now + wait_time;

	sprintf(str, "Source: %s, uid: %s, did: %s, initial device id: %s, wait time: %i, time now: %li, execute_time: %li, card_id: %s, callerid: %s, dial plan id: %s, cc_did: %s", source, uid, did, device_id, wait_time, time_now, execute_time, card_id, callerid, dp_id, cc_did);
	AGITool_verbose(&agi, &res, str, 0);


	// call file
	
	sprintf(fname, "mor_cb_%s", uid);
	sprintf(temp_file, "/tmp/%s", fname);
	sprintf(spool_file, "/var/spool/asterisk/outgoing/%s", fname); 
	
	sprintf(callfile, "Channel: Local/%s@mor/n\nMaxRetries: 0\nRetryTime: 120\nWaitTime: 120\nAccount: %s\nContext: mor\nExtension: %s\nPriority: 1\nSet: MOR_CALLBACK=1\nSet: MOR_UID=%s\nSet: MOR_CALLBACK_SRC=%s\nSet: MOR_CALLBACK_START=%li\nSet: MOR_CARD_ID=%s\nSet: MOR_DP_ID=%s\nSet: MOR_CC_DID=%s\n", source, device_id, did, uid, callerid, execute_time, card_id, dp_id, cc_did);
	
	// Write to temp file
	cfile = fopen(temp_file,"w");
	fprintf(cfile,"%s\n",callfile);	    
	fclose(cfile); 

	// Touch file to change it's execution time
    
        t1 = time(NULL) + wait_time;
	localtime_r(&t1, &tm);
	strftime(touch_time, 128, TOUCH_TIME_FORMAT, &tm);
		
	sprintf(systcmd, "touch -m -t %s %s", touch_time, temp_file);
	system(systcmd); 

	// execute call file
	//rename(temp_file, spool_file); 

	sprintf(systcmd, "mv %s %s", temp_file, spool_file);
	system(systcmd); 

	sprintf(str, "Callfile %s will be executed at: %s\n", fname, touch_time);
	AGITool_verbose(&agi, &res, str, 0);


	AGITool_verbose(&agi, &res, "MOR Callback Activation AGI script completed.", 0);
	AGITool_verbose(&agi, &res, "", 0);

	AGITool_Destroy(&agi);

	
//	mysql_close(&mysql);  

	return 0;
}


