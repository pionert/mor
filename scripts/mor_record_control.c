/*
*
*   MOR Record control script
*   Copyright Mindaugas Kezys / Kolmisoft 2009-2013
*
*   v0.1.6
*
*   2009.07.23 v0.1.1 FIX: in SQL for devices LEFT JOIN
*   2009.07.23 v0.1.2 FIX: do not send email twice
*   2009.08.10 v0.1.3 FIX: read devices.record to determine if user should receive email with deleted recording when he does not know his 
*   2010.05.12 v0.1.4 FIX: do not delete recording if user wants it on server
*   2012.09.18 v0.1.5 FIX: delete recording if hdd free space < 10% (send deleted recording to user via email)
*   2013.01.31 v0.1.6 FIX: reseller users now get recording from reseller email, not default system admin email

*       Script checks if recording should be sent to email/delete it afterwards, does it fit into hdd space assigned to user, if not - sends it to users email and deletes from hdd
*
*/

#define _BSD_SOURCE

#include <stdlib.h>
#include <mysql.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <sys/stat.h>
#include <sys/time.h>

/* Defines */

#define DATE_FORMAT "%Y-%m-%d"
#define TIME_FORMAT "%T" 
#define TOUCH_TIME_FORMAT "%Y%m%d%H%M.%S"


/* Structures */

/* Variables */

char dbhost[40], dbname[20], dbuser[20], dbpass[20];
int dbport;

int SHOW_SQL = 0, DEBUG = 0, EXECUTE_CALL_FILES = 1;

static MYSQL    mysql;

int server_id = 1;


// specific vars

char uniqueid[128] = "";
int src_device_id = 0;
int src_user_id = 0;

int dst_device_id = 0;
int dst_user_id = 0;
int visible_to_user = 1;

int src_owner_id = 0;
int dst_owner_id = 0;

// server details
int use_external_server = 0;
char server_ip[20] = "";
int server_port = 22;
char server_login[30] = "root";
double server_max_space = 100;

// call details

int call_id = 0;
char call_calldate[30] = "";
char call_src[128] = "";
char call_dst[128] = ""; 
int call_user_id = 0;
int call_billsec = 0;

// src details
char src_email1[50] = ""; // where to send if hdd limit reached #1
char src_email2[50] = ""; // where to send if hdd limit reached #2
char src_email3[50] = ""; // where to send for device
int  src_quota = 0; // hdd quota
int  src_send = 0; // should we send to email?
int  src_keep = 0; // should we keep rec on hdd after sent to email?
int  src_sum = 0;  // space already used for previous recodings
int  src_user_forced = 0;
int  src_device_forced = 0;
int  src_device_record = 0; // does src user know about recording?

// dst details
char dst_email1[50] = ""; // where to send if hdd limit reached #1
char dst_email2[50] = ""; // where to send if hdd limit reached #2
char dst_email3[50] = ""; // where to send for device
int  dst_quota = 0; // hdd quota
int  dst_send = 0; // should we send to email?
int  dst_keep = 0; // should we keep rec on hdd after sent to email?
int  dst_sum = 0;  // space already used for previous recodings
int  dst_user_forced = 0;
int  dst_device_forced = 0;
int  dst_device_record = 0; // does src user know about recording?

// email data
char Email_Smtp_Server[30] = "";
char Email_Domain[30] = "";
char Email_port[30] = "25";
char Email_Login[30] = "";
char Email_Password[30] = "";
char Email_from[50] = "mor@softswitch.com";
char rec_new_subject[1024] = "";
char rec_new_body[1048576] = "";
char rec_del_subject[1024] = "";
char rec_del_body[1048576] = "";

// other vars
char full_file_name_wav[512] = "";
char full_file_name_mp3[512] = "";
long local_mp3_size = 0;
long remote_mp3_size = 0;

char src_del_email[50] = "";
char dst_del_email[50] = "";    


int local = 1; // is recording on local server?

/* Function declarations */

void get_details(int src);
void get_email_data(int src);
void send_email(int type, int src);

//void get_device_details(int device_id, int *user_id);
//void get_call_details();

void read_config();
static int mysql_connect();



void my_debug(char *msg) {
    FILE *file;
    file = fopen("/var/log/mor/record_file.log","a+");
    fprintf(file,"%s - %s\n", uniqueid, msg);
    fclose(file);
}
        
void my_debug_int(int msg) {
    FILE *file;
    file = fopen("/var/log/mor/record_file.log","a+");
    fprintf(file,"%s - %i\n", uniqueid, msg);
    fclose(file);
}


char *replace_str(char *str, char *orig, char *rep)
{
    static char buffer[1048576];
    char *p;
    
    if(!(p = strstr(str, orig)))  // Is 'orig' even in 'str'?
    return str;
         
    strncpy(buffer, str, p-str); // Copy characters from 'str' start to 'orig' st$
    buffer[p-str] = '\0';
              
    sprintf(buffer+(p-str), "%s%s", rep, p+strlen(orig));
                
    return buffer;
}
                  
                  

int file_exists(char *filename){
  FILE *file;

  if (( file = fopen(filename, "r") )) {
    fclose(file);
    return 1;
  }
  return 0;
}

long file_size(char* filename){

  struct stat stbuf;
  stat(filename, &stbuf);
  return stbuf.st_size;     
}                                                                             


int main(int argc, char *argv[]) {


    struct tm tm;
    struct timeval t0, t1;
    char mdate[20];
    char mtime[20];
    time_t t;

    char buff[2048] = "";

    /* Get current time */
    gettimeofday(&t0, NULL);
    localtime_r(&t, &tm);
    strftime(mdate, 128, DATE_FORMAT, &tm);
    strftime(mtime, 128, TIME_FORMAT, &tm);

    int  src_delete_rec = 0;
    int  dst_delete_rec = 0;    


    // assign variables

    if (argv[1])
        strcpy(uniqueid, argv[1]);
    if (argv[2])
        local = atoi(argv[2]);


    my_debug("mor_record_control script starting");    



    if (!strlen(uniqueid)) {
        my_debug("No filename/uniqueid provided, aborting...");
        return 0;
    }

    if (local){
        sprintf(full_file_name_mp3, "/var/spool/asterisk/monitor/%s.mp3", uniqueid);
    } else {
        sprintf(full_file_name_mp3, "/usr/local/mor/recordings/%s.mp3", uniqueid);    
    }


    // info to log file
    //my_debug("");
    sprintf(buff, "Date: %s %s, uniqueid: %s, local: %i", mdate, mtime, uniqueid, local);
    my_debug(buff);

    // check for errors


    if (!file_exists(full_file_name_mp3)){
        sprintf(buff, "No recording %s found, aborting...", full_file_name_mp3);
        my_debug(buff);    
        return 0;
    }






    // connect to db
    
    read_config();

    if (!mysql_connect()) 
    return 0;
    
    // collect data

    get_details(1); //for src device
    get_details(0); //for dst device

    int hdd_usage = 0;
    int forced_delete_rec = 0;
    FILE *pipe;

    if (local) {
        pipe = popen("df /var/spool/asterisk/monitor | grep -Po '(?=\\d+%)\\d+'", "r");
    } else {
        pipe = popen("df /usr/local/mor/recordings | grep -Po '(?=\\d+%)\\d+'", "r");  
    }

    if (pipe == NULL) {
        hdd_usage = 0; // if we can't get disk usage, keep recorded files
    } else {
        char pipe_buffer[32] = { 0 };
        fgets(pipe_buffer, 32, pipe);
        hdd_usage = atoi(pipe_buffer);
    }

    pclose(pipe);

    if (local) {
        sprintf(buff, "Used space on /var/spool/asterisk/monitor is: %d%%", hdd_usage);
        my_debug(buff);
    } else {
        sprintf(buff, "Used space on /usr/local/mor/recordings is: %d%%", hdd_usage);
        my_debug(buff);
    }

    // check if hdd free space is > 90%
    if (hdd_usage > 90 && hdd_usage <= 100) {
        forced_delete_rec = 1;
        my_debug("NOT ENOUGH space on the server to store current recording. Recording will be sent to user via email and deleted from the server.");

        // to which email should we send recording (SRC)
        if (strlen(src_email1)){
            strcpy(src_del_email, src_email1);
        } else {
            strcpy(src_del_email, src_email2);      
        }

        // to which email should we send recording (DST)
        if (strlen(dst_email1)){
            strcpy(dst_del_email, dst_email1);
        } else {
            strcpy(dst_del_email, dst_email2);      
        }
    } else {
        // checking if hdd limit is not overdue
        // quota = 0 means unlimited space

        // check for src
        if (((src_quota) && (src_quota > src_sum) && ((src_quota - src_sum) > local_mp3_size)) || (!src_quota)){

            sprintf(buff, "SRC quota: %i, taken: %i -> ENOUGH space to store current recording", src_quota, src_sum);
            my_debug(buff);            

        } else {

            src_delete_rec = 1; // mark recording to be deleted by src

            sprintf(buff, "SRC quota: %i, taken: %i -> NOT ENOUGH space to store current recording", src_quota, src_sum);
            my_debug(buff);            

            // to which email should we send recording
            if (strlen(src_email1)){
                strcpy(src_del_email, src_email1);
            } else {
                strcpy(src_del_email, src_email2);      
            }
            
        }


        // check for dst
        if (((dst_quota) && (dst_quota > dst_sum) && ((dst_quota - dst_sum) > local_mp3_size)) || (!dst_quota)){

            sprintf(buff, "DST quota: %i, taken: %i -> ENOUGH space to store current recording", dst_quota, dst_sum);
            my_debug(buff);            

        } else {

            dst_delete_rec = 1; // mark recording to be deleted by dst

            sprintf(buff, "DST quota: %i, taken: %i -> NOT ENOUGH space to store current recording", dst_quota, dst_sum);
            my_debug(buff);            

            // to which email should we send recording
            if (strlen(dst_email1)){
                strcpy(dst_del_email, dst_email1);
            } else {
                strcpy(dst_del_email, dst_email2);      
            }
            
        }
    }




    //---------- real action -------------

    if (src_delete_rec || forced_delete_rec){
        if (strlen(src_del_email)){

            if (src_device_record){
                sprintf(buff, "SRC Recording will be sent to %s", src_del_email);
                my_debug(buff);            
                send_email(2,1);
            } else {
                my_debug("SRC User does not know his calls are recorded. Recording is delete and not sent to user.");       
            }
        
        } else {
            my_debug("SRC No email to which send recording.");
        }
    } else {
        // rec not deleted, so maybe src wants to get it to email?
        if ((src_send) && (strlen(src_email3))){
            sprintf(buff, "SRC wants to get rec to his email. Sending to %s", src_email3);
            my_debug(buff);
            send_email(1,1);
        }
    
    }

    if (dst_delete_rec || forced_delete_rec){
        if (strlen(dst_del_email)){

            if (strcmp(src_del_email, dst_del_email)){

                if (dst_device_record){
                    sprintf(buff, "DST Recording will be sent to %s", dst_del_email);
                    my_debug(buff);            
                    send_email(2,0);
                } else {
                    my_debug("DST User does not know his calls are recorded. Recording is delete and not sent to user.");
                }

            } else {
                my_debug("SRC and DST emails match. Will not send to same email.");
            }
        
        } else {
            my_debug("DST No email to which send recording.");
        }
    } else {
        // rec not deleted, so maybe dst wants to get it to email?
        if ((dst_send) && (strlen(dst_email3))){

            if (strcmp(dst_email3, src_email3)){
                sprintf(buff, "DST wants to get rec to his email. Sending to %s", dst_email3);
                my_debug(buff);
                send_email(1,0);
            } else {
                my_debug("DST user email matches SRC email. Will not send twice.");     
            }

        }
    
    }
    
    
    // -------------- hide recording for users if necessary --------------
    
    
    if ( (forced_delete_rec) || (src_delete_rec) || ((!src_delete_rec) && (src_send && (!src_keep))) ){
        // hiding for src
        sprintf(buff,"UPDATE recordings SET visible_to_user = 0 WHERE uniqueid = %s;", uniqueid);
        my_debug(buff);
        mysql_query(&mysql,buff);
    }


    if ( (forced_delete_rec) || (dst_delete_rec) || ((!dst_delete_rec) && (dst_send && (!dst_keep))) ){
        // hiding for dst
        sprintf(buff,"UPDATE recordings SET visible_to_dst_user = 0 WHERE uniqueid = %s;", uniqueid);
        my_debug(buff);
        mysql_query(&mysql,buff);
    }


    int src_delete = 0;

    // SRC DELETE IF neither admin, nor user is set recording
    if (src_device_record == 0 && src_device_forced == 0) src_delete = 1;
    // SRC DELETE IF email was sent and user/admin wants not to keep recordings in hdd
    if (src_send && !src_keep) src_delete = 1;
    // SRC KEEP IF recording is forced to src user
    if (src_user_forced) src_delete = 0;

    int dst_delete = 0;

    // DST DELETE IF neither admin, nor user is set recording
    if (dst_device_record == 0 && dst_device_forced == 0) dst_delete = 1;
    // DST DELETE IF email was sent and user/admin wants not to keep recordings in hdd
    if (dst_send && !dst_keep) dst_delete = 1;
    // DST KEEP IF recording is forced to dst user
    if (dst_user_forced) dst_delete = 0;

    // delete recording if both src and dst users used all their hdd space and recording is not forced to users
    if (src_delete_rec && dst_delete_rec && src_device_forced == 0 && dst_device_forced == 0 && src_user_forced == 0 && dst_user_forced == 0) {
        src_delete = 1;
        dst_delete = 1;
    }

    
    // ------- delete mp3 file -----------

    // deleting only then when it is not necessary to keep it for admin
    // why also not for user?
    // we should not delete if visible_to_(dst_)user == 1
    if (forced_delete_rec || (src_delete && dst_delete)) {
    
        sprintf(buff, "rm -fr %s", full_file_name_mp3);
        system(buff);
        sprintf(buff, "Recording %s deleted from HDD", full_file_name_mp3);
        my_debug(buff);            
        
        // mark as deleted, or better delete at all
        // sprintf(buff,"UPDATE recordings SET deleted = 1 WHERE uniqueid = %s;", uniqueid);
        sprintf(buff,"DELETE FROM recordings WHERE uniqueid = %s;", uniqueid);
        my_debug(buff);
        mysql_query(&mysql,buff);
    
    }

    // bye

    mysql_close(&mysql);    

    gettimeofday(&t1, NULL);
    // printf("End of MOR Auto-Dialer Cron script.\nTotal campaigns: %i, total numbers: %i\nExecution time: %f s\n\n", total_campaigns, total_numbers, (float) (ut1-ut0)/1000000);    
                          
    // gets(NULL);

    my_debug("mor_record_control script completed.");

    return 0;

}



/* Functions */


// send specified email
// type 1 - new, 2 - delete
// src 1 - src, 0 - dst
void send_email(int type, int src) {

    char email_subject[1024] = "";
    char email_body[1048576] = "";
    char email[128] = "";
    int attach_rec = 1;     // should we attach recording?
    char buff[2048] = "";
    char emailcmd[2048] = "";

    // get email data for src/dst
    get_email_data(src);    

    if (type == 1) {
        // new recording email
        strcpy(email_subject, rec_new_subject);
        strcpy(email_body, rec_new_body);

        if (src){
            strcpy(email, src_email3);
        } else {
            strcpy(email, dst_email3);  
        }
    } 
    
    if (type == 2) {
        // delete recording email
        strcpy(email_subject, rec_del_subject);
        strcpy(email_body, rec_del_body);    

        if (src) {
            strcpy(email, src_del_email);
        } else {
            strcpy(email, dst_del_email);   
        }
    }

    // --------- format email body ----------

    strcpy(email_body, replace_str(email_body, "<% calldate %>", call_calldate));
    strcpy(email_body, replace_str(email_body, "<% source %>", call_src));
    strcpy(email_body, replace_str(email_body, "<% destination %>", call_dst));
    sprintf(buff, "%i", call_billsec);
    strcpy(email_body, replace_str(email_body, "<% billsec %>", buff));    

    // if email body is empty, sendEmail will not send email
    if (strlen(email_body) == 0) strcpy(email_body, " ");
    
    // --------- send email ---------
    
    // format send string
    strcpy(emailcmd, "/usr/local/mor/sendEmail ");
    // 'from' field
    if (strlen(Email_from)){
        sprintf(buff, " -f '%s' ", Email_from);
        strcat(emailcmd, buff); 
    }
    // 'username' field
    if (strlen(Email_Login) ){
        sprintf(buff, " -xu '%s' ", Email_Login);
        strcat(emailcmd, buff); 
    }
    // 'password' field
    if (strlen(Email_Password)){
        sprintf(buff, " -xp '%s' ", Email_Password);
        strcat(emailcmd, buff); 
    }
    // 'attachment' field
    if (attach_rec){
        sprintf(buff, " -a '%s' ", full_file_name_mp3);
        strcat(emailcmd, buff); 
    }

    sprintf(emailcmd, "%s -t '%s' -u '%s' -s '%s:%s' -m '%s' -o tls='auto'", emailcmd, email, email_subject, Email_Smtp_Server, Email_port, email_body);        

    my_debug(emailcmd);
    system(emailcmd);        
    
}






void get_device_details(int device_id, int *user_id) {

    MYSQL_RES   *result;
    MYSQL_ROW   row;
    char sqlcmd[2048] = "";    
    int i;    

    char buff[2048] = "";

    if (!device_id) {
        my_debug("No details retrieved for device (id = 0)");
        return;
    }


    sprintf(sqlcmd,"SELECT user_id FROM devices WHERE id = %i;", device_id);
    
        //if (SHOW_SQL) printf("SQL: %s\n", sqlcmd);    

    if (mysql_query(&mysql,sqlcmd))
    {
        // error    
        
    }
    else // query succeeded, process any data returned by it
    {
        result = mysql_store_result(&mysql);
        if (result)  // there are rows
        {
            i = 0;
            while ((row = mysql_fetch_row(result)))
            {

                if (row[0]) *user_id = atoi(row[0]);

                sprintf(buff, "Device details retrieved: device id: %i, user id: %i", device_id, *user_id);
                my_debug(buff);
                 
                i++;
            }
            mysql_free_result(result);
        }
        else  // mysql_store_result() returned nothing; should it have?
        {
            if(mysql_field_count(&mysql) == 0)
            {           }
            else // mysql_store_result() should have returned data
            {
            
            }
        }
    }

}


void get_details(int src) {


    MYSQL_RES   *result;
    MYSQL_ROW   row;
    char sqlcmd[2048] = "";    
    int  i;    
    char src_sql[10] = "src";
    char src_owner_sql[10] = "";
    char buff[2048];

    char email1[50] = ""; // where to send if hdd limit reached #1
    char email2[50] = ""; // where to send if hdd limit reached #2
    char email3[50] = ""; // where to send for device
    int  quota = 0; // hdd quota
    int  send = 0; // should we send to email?
    int  keep = 0; // should we keep rec on hdd after sent to email?
    int  sum = 0;  // space already used for previous recodings
    int  user_forced = 0;
    int  device_forced = 0;
    int  device_record = 0;


    if (!src){
        strcpy(src_sql, "dst");
        strcpy(src_owner_sql, "dst_");
    }
    
    sprintf(sqlcmd,"SELECT devices.id, users.recordings_email, users.recording_hdd_quota, devices.recording_to_email, devices.recording_keep, devices.recording_email, addresses.email, calls.calldate, calls.billsec, calls.src, calls.dst, A.sum, recordings.size, users.recording_forced_enabled, devices.record_forced, devices.record, users.owner_id FROM users JOIN devices ON (devices.user_id = users.id) JOIN addresses ON (addresses.id = users.address_id)  JOIN recordings ON (recordings.%s_device_id = devices.id) JOIN calls ON (calls.id = recordings.call_id) LEFT JOIN    (SELECT user_id, SUM(size) AS 'sum' FROM recordings WHERE visible_to_user = 1 GROUP BY user_id) AS A ON (A.user_id = recordings.%suser_id) WHERE recordings.uniqueid = '%s'; ", src_sql, src_owner_sql, uniqueid);
    
    //if (SHOW_SQL) printf("SQL: %s\n", sqlcmd);    

    //my_debug(sqlcmd);

    if (mysql_query(&mysql,sqlcmd))
    {
        // error    
        
    }
    else // query succeeded, process any data returned by it
    {
        result = mysql_store_result(&mysql);
        if (result)  // there are rows
        {
            i = 0;
            while ((row = mysql_fetch_row(result))) {

                if (row[0]) {
                    if (row[1]) strcpy(email1, row[1]);
                    if (row[2]) quota = atoi(row[2]);
                    if (row[3]) send = atoi(row[3]);
                    if (row[4]) keep = atoi(row[4]);                        
                    if (row[5]) strcpy(email3, row[5]); 
                    if (row[6]) strcpy(email2, row[6]); 
                    if (row[7]) strcpy(call_calldate, row[7]); 
                    if (row[8]) call_billsec = atoi(row[8]);                        
                    if (row[9]) strcpy(call_src, row[9]); 
                    if (row[10]) strcpy(call_dst, row[10]); 
                    if (row[11]) sum = atoi(row[11]);
                    if (row[12]) local_mp3_size = atoi(row[12]);
                    if (row[13]) user_forced = atoi(row[13]);
                    if (row[14]) device_forced = atoi(row[14]);
                    if (row[15]) device_record = atoi(row[15]);
                    if (row[16]) {
                        if (src) {
                            src_owner_id = atoi(row[16]);
                        } else {
                            dst_owner_id = atoi(row[16]);
                        } 
                    } 

                    sprintf(buff, "Device (%s) details retrieved: email1: %s, email2: %s, email3: %s, quota: %i, send: %i, keep: %i, sum: %i, call date: %s, billsec: %i, src: %s, dst: %s, mp3 size: %li, user_forced: %i, device_forced: %i, device_record: %i", src_sql, email1, email2, email3, quota, send, keep, sum, call_calldate, call_billsec, call_src, call_dst, local_mp3_size, user_forced, device_forced, device_record);
        
                } else {

                    sprintf(buff, "No data for %s device retrieved...", src_sql);
            
                }
             
                my_debug(buff);

                i++;
            }

            mysql_free_result(result);
        }
        else  // mysql_store_result() returned nothing; should it have?
        {
            if(mysql_field_count(&mysql) == 0)
            {           }
            else // mysql_store_result() should have returned data
            {
            
            }
        }
    }


    if (src) {
        strcpy(src_email1, email1);
        strcpy(src_email2, email2);
        strcpy(src_email3, email3);
        src_quota = quota;
        src_send = send;
        src_keep = keep;
        src_sum = sum;
        src_user_forced = user_forced;
        src_device_forced = device_forced;
        src_device_record = device_record;
    } else {
        strcpy(dst_email1, email1);
        strcpy(dst_email2, email2);
        strcpy(dst_email3, email3);
        dst_quota = quota;
        dst_send = send;
        dst_keep = keep;
        dst_sum = sum;
        dst_user_forced = user_forced;
        dst_device_forced = device_forced;
        dst_device_record = device_record;
    }

}



void get_email_data(int src) {

    MYSQL_RES   *result;
    MYSQL_ROW   row;
    char sqlcmd[2048] = "";    
    int i;    

    char buff[2048];

    int owner_id = 0;

    static int got_email_data = 0; // have we already called this function?
    static int last_owner_id = 0;  // save last owner ID 

    if (src) {
        owner_id = src_owner_id;
    } else {
        owner_id = dst_owner_id;
    }

    // check if we already have email data for this owner
    if (last_owner_id == owner_id && got_email_data) {
        // don't reread the same data, return
        return;
    }

    last_owner_id = owner_id;
    
    sprintf(sqlcmd,"SELECT (SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_Smtp_Server'), (SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_port'), (SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_Login'), (SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_Password'), (SELECT value FROM conflines WHERE owner_id = %d AND name = 'Email_from'), (SELECT subject FROM emails WHERE name = 'recording_new' AND owner_id = %d), (SELECT body FROM emails WHERE name = 'recording_new' AND owner_id = %d), (SELECT subject FROM emails WHERE name = 'recording_delete' AND owner_id = %d), (SELECT body FROM emails WHERE name = 'recording_delete' AND owner_id = %d);", owner_id, owner_id, owner_id, owner_id, owner_id, owner_id, owner_id, owner_id, owner_id);
    
    // my_debug(sqlcmd);


    if (mysql_query(&mysql,sqlcmd))
    {
        // error    
        
    }
    else // query succeeded, process any data returned by it
    {
        result = mysql_store_result(&mysql);
        if (result)  // there are rows
        {
            i = 0;
            while ((row = mysql_fetch_row(result)))
            {

                if (row[0]) strcpy(Email_Smtp_Server, row[0]);
                if (row[1]) strcpy(Email_port, row[1]);
                if (row[2]) strcpy(Email_Login, row[2]); 
                if (row[3]) strcpy(Email_Password, row[3]);
                if (row[4]) strcpy(Email_from, row[4]);
                if (row[5]) strcpy(rec_new_subject, row[5]);
                if (row[6]) strcpy(rec_new_body, row[6]);           
                if (row[7]) strcpy(rec_del_subject, row[7]);
                if (row[8]) strcpy(rec_del_body, row[8]);           

                
                sprintf(buff, "Email details retrieved: server: %s, port: %s, login: %s, password: %s, from: %s, rec_new_subject: '%s', rec_del_subject: '%s', owner_id: %d", Email_Smtp_Server, Email_port, Email_Login, Email_Password, Email_from, rec_new_subject, rec_del_subject, owner_id);
                my_debug(buff);

                i++;
            }
            mysql_free_result(result);
        }
        else  // mysql_store_result() returned nothing; should it have?
        {
            if(mysql_field_count(&mysql) == 0)
            {           }
            else // mysql_store_result() should have returned data
            {
            
            }
        }
    }

    // check that we got email data
    got_email_data = 1;
}


void read_config(){
    FILE    *file;
    char var[200], val[200];

    file = fopen("/var/lib/asterisk/agi-bin/mor.conf", "r");

    /* Default values */
    strcpy(dbhost, "localhost");
    strcpy(dbname, "mor");
    strcpy(dbuser, "mor");
    strcpy(dbpass, "mor");
    dbport = 3306;
    //strcpy(dbport, "3306");

//    calls_one_time = 20;
//    cron_interval = 10;

    /* Read values from conf file */    
    while (fscanf(file, "%s = %s", var, val) != EOF) {

    if (!strcmp(var, "host")) {
        strcpy(dbhost, val);        
    } else {
    if (!strcmp(var, "db")) {
        strcpy(dbname, val);        
    } else {
    if (!strcmp(var, "user")) {
        strcpy(dbuser, val);        
    } else  {
    if (!strcmp(var, "secret")) {
        strcpy(dbpass, val);        
    } else {
    if (!strcmp(var, "port")) {
        //strcpy(dbport, val);        
        dbport = atoi(val);
    } else {
    if (!strcmp(var, "show_sql")) {
        SHOW_SQL = atoi(val);        
    } else {
    if (!strcmp(var, "debug")) {
        DEBUG = atoi(val); 
    } else {
    if (!strcmp(var, "server_id")) {
        server_id = atoi(val);        
    } else {
    } } } } } } } }

    }
    
    fclose(file);

//    my_debug("server_id");
//    my_debug_int(server_id);

//    if (DEBUG) printf("DB config. Host: %s, DB name: %s, user: %s, psw: %s, port: %i, SHOW_SQL: %i, DEBUG: %i, server_id\n", dbhost, dbname, dbuser, dbpass, dbport, SHOW_SQL, DEBUG);

}


static int mysql_connect()
{
    char my_database[50];

    strcpy(my_database, dbname);
                            
    if(*dbhost && *dbuser && *dbpass && *my_database) {
        if(!mysql_init(&mysql)) {
        printf("Insufficient memory to allocate MySQL resource.\n");
            return 0;
    }
        if(mysql_real_connect(&mysql, dbhost, dbuser, dbpass, my_database, dbport, NULL, 0)) {
            //if (DEBUG) printf("Successfully connected to database.\n");
            return 1;
        } else {
            printf("Failed to connect database server %s on %s. Check debug for more info.\n", dbname, dbhost);
            printf("Cannot Connect: %s\n", mysql_error(&mysql));
            return 0;
        }
    } else {
        if (mysql_ping(&mysql) != 0) {
            printf("Failed to reconnect. Check debug for more info.\n");
            printf("Server Error: %s\n", mysql_error(&mysql));
            return 0;
        }

        if (mysql_select_db(&mysql, my_database) != 0) {
            printf("Unable to select database: %s. Still Connected.\n", my_database);
            printf("Database Select Failed: %s\n", mysql_error(&mysql));
            return 0;
        }

        //if (DEBUG) printf("DB connected.\n");
        return 1;
    }
}
