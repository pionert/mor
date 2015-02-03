/*
*
*	MOR Callback Activation AGI script
*	Copyright Mindaugas Kezys / Kolmisoft 2007-2015
*
*	v0.1.7
*
*   2014-08-11   v0.1.7  Pass MOR_INIT_DEVICE_TARIFF_ID and MOR_INIT_DEVICE_TARIFF_TYPE
*   2011-05-26   v0.1.6  Prefix Callback Support
*   2010-10-12   v0.1.5  Pass MOR_DP_ID, MOR_CC_DID, bugfix to callback
*   2009-12-11   v0.1.4  CallerID support
*   2009-07-09   v0.1.3  RetryTime 120s
*   2009-06-17   v0.1.2  WaitTime 120s
*   2009-06-02   v0.1.1  Calling Card support
*
*/


#include <stdio.h>
#include <stdarg.h>
#include <time.h>
#include "cagi.c"

#define TOUCH_TIME_FORMAT "%Y%m%d%H%M.%S"

//	variables

char source[1024] = "";
char uid[1024] = "";
char did[1024] = "";
int wait_time = 0;
char device_id[1024] = "";
char init_device_tariff_id[1024] = "";
char init_device_tariff_type[1024] = "";
char card_id[1024] = "";
char callerid[1024] = "";
char dp_id[1024] = "";
char cc_did[1024] = "";
char cb_dst[1024] = "";

AGI_TOOLS agi;
AGI_CMD_RESULT res;

//	main function

int main() {

	char str[1024] = "";
	char buff[1024] = "";
	char systcmd[256] = "";

	time_t time_now = time(NULL);
	long int execute_time = 0;

	// call file vars
	FILE *cfile = NULL;
	char callfile[2048] = "";
    char fname[128] = "", temp_file[128] = "", spool_file[128] = "";

	char touch_time[64] = "";
	struct tm tm;
	time_t t1 = 0;

	AGITool_Init(&agi);
	AGITool_verbose(&agi, &res, "", 0);
	AGITool_verbose(&agi, &res, "MOR Callback Activation AGI script started.", 0);
	strcpy(source, AGITool_ListGetVal(agi.agi_vars, "agi_extension"));
	AGITool_get_variable2(&agi, &res, "MOR_CB_UID", uid, sizeof(uid));
	AGITool_get_variable2(&agi, &res, "MOR_CB_DID", did, sizeof(did));
	AGITool_get_variable2(&agi, &res, "MOR_CB_WAIT_TIME", buff, sizeof(buff));
	wait_time = atoi(buff);
    AGITool_get_variable2(&agi, &res, "MOR_CB_DEVICE_ID", device_id, sizeof(device_id));
    AGITool_get_variable2(&agi, &res, "MOR_CB_INIT_DEVICE_TARIFF_ID", init_device_tariff_id, sizeof(init_device_tariff_id));
	AGITool_get_variable2(&agi, &res, "MOR_CB_INIT_DEVICE_TARIFF_TYPE", init_device_tariff_type, sizeof(init_device_tariff_type));
	AGITool_get_variable2(&agi, &res, "MOR_CARD_ID", card_id, sizeof(card_id));
	AGITool_get_variable2(&agi, &res, "MOR_CB_CALLERID", callerid, sizeof(callerid));
    AGITool_get_variable2(&agi, &res, "MOR_DP_ID", dp_id, sizeof(dp_id));
    AGITool_get_variable2(&agi, &res, "MOR_CC_DID", cc_did, sizeof(cc_did));
    AGITool_get_variable2(&agi, &res, "MOR_CB_DST", cb_dst, sizeof(cb_dst));

	execute_time = time_now + wait_time;

	sprintf(str, "Source: %s, uid: %s, did: %s, initial device tariff id: %s, initial device tariff type: %s, callback device: %s, wait time: %i, time now: %li, execute_time: %li, card_id: %s, callerid: %s, dial plan id: %s, cc_did: %s, cb_dst: %s", source, uid, did, init_device_tariff_id, init_device_tariff_type, device_id, wait_time, time_now, execute_time, card_id, callerid, dp_id, cc_did, cb_dst);
	AGITool_verbose(&agi, &res, str, 0);

	// call file
	sprintf(fname, "mor_cb_%s", uid);
	sprintf(temp_file, "/tmp/%s", fname);
	sprintf(spool_file, "/var/spool/asterisk/outgoing/%s", fname);
	sprintf(callfile, "Channel: Local/%s@mor/n\nMaxRetries: 0\nRetryTime: 120\nWaitTime: 120\nAccount: %s\nContext: mor\nExtension: %s\nPriority: 1\nSet: MOR_CALLBACK=1\nSet: MOR_UID=%s\nSet: MOR_CALLBACK_SRC=%s\nSet: MOR_CALLBACK_START=%li\nSet: MOR_CARD_ID=%s\nSet: MOR_DP_ID=%s\nSet: MOR_CC_DID=%s\nSet: MOR_CB_DST=%s\nSet: MOR_CB_LEGA_DST=%s\nSet: MOR_CB_INIT_DEVICE_TARIFF_ID=%s\nSet: MOR_CB_INIT_DEVICE_TARIFF_TYPE=%s\n", source, device_id, did, uid, callerid, execute_time, card_id, dp_id, cc_did, cb_dst, source, init_device_tariff_id, init_device_tariff_type);

	// write to temp file
	cfile = fopen(temp_file, "w");
	fprintf(cfile, "%s\n", callfile);
	fclose(cfile);

	// touch file to change it's execution time
    t1 = time(NULL) + wait_time;
	localtime_r(&t1, &tm);
	strftime(touch_time, 128, TOUCH_TIME_FORMAT, &tm);

	sprintf(systcmd, "touch -m -t %s %s", touch_time, temp_file);
	system(systcmd);

	sprintf(systcmd, "mv %s %s", temp_file, spool_file);
	system(systcmd);

	sprintf(str, "Callfile %s will be executed at: %s\n", fname, touch_time);
	AGITool_verbose(&agi, &res, str, 0);
	AGITool_verbose(&agi, &res, "MOR Callback Activation AGI script completed.", 0);
	AGITool_verbose(&agi, &res, "", 0);
	AGITool_Destroy(&agi);

	return 0;
}
