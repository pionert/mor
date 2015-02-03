/*
*
*    MOR Fax2Email AGI script
*    Copyright Mindaugas Kezys / Kolmisoft 2007-2013
*
*    v0.1.11
*    
*    2014.06.20 v0.1.11 - get FROM_SENDER by owner_id
*    2013.02.14 v0.1.10 - using smtp port from database
*    2011.08.30 v0.1.9  - Log file changed to /var/log/mor/fax2email.log
*    2010.10.01 v0.1.8  - FROM_SENDER value not used anymore
*    2009.01.16 v0.1.7  - fixed bug for retrieving email settings from conflines
*    2008.11.10 v0.1.6  - strict check for pdf_file_size which sometimes is 134529332
*    2008.08.24 v0.1.5  - mime-construct changed to sendEmail and mail server settings red from DB
*    2008.08.23 v0.1.4  - read FROM_SENDER from DB if not got from dial plan
*
*/


#include <stdio.h>
#include <stdarg.h>
#include <mysql.h>
#include <mysql/errmsg.h>
#include <time.h>
#include <sys/stat.h>

#include "cagi.c"


/*    Structures    */

struct em {
    char email[100];
};

/*    Variables    */

char dbhost[40] = "";
char dbname[20] = "";
char dbuser[20] = "";
char dbpass[20] = "";
int dbport = 0;

MYSQL mysql;

AGI_TOOLS agi;
AGI_CMD_RESULT res;

int user_id = 0;
int fax_device_id = 0;
int pdffax_id = 0;
char fax_file_name[100] = "";
char fax_folder[100] = "";
char pdf_file[1024] = "", tif_file[1024] = "";
char fax_sender[1024] = "";
char from_sender[1024] = "";
char from_sender_db[1024] = "";
int fax_device_owner_id = 0;

char mail_server[1024] = "";
char mail_username[1024] = "";
char mail_password[1024] = "";
int  mail_port = 0;

char mail_server_line[1024] = "";

char systcmd[1024] = "";
char sqlcmd[2048] = "";

struct em emails[50];
int total_emails = 0;

char datetime[1024] = "";
int pdf_file_size = 0;


/*    Function definitions    */


int mysql_connect();
int get_emails();
int get_owner_id();
void convert2pdf();
void read_config();
void pdffax_status(char *status);


void my_debug(char *msg) {
    FILE *file;
    file = fopen("/var/log/mor/fax2email.log", "a+");
    fprintf(file, "%s\n", msg);
    fclose(file);
}


void my_debug_int(int msg) {
    FILE *file;
    file = fopen("/var/log/mor/fax2email.log", "a+");
    fprintf(file, "%i\n", msg);
    fclose(file);
}


long FileSize(char *filename) {
    struct stat stbuf;
    stat(filename, &stbuf);
    if (stbuf.st_size > 130000000) {
        stbuf.st_size = 0;
    }
    return stbuf.st_size;
}


int file_exists (char *fileName) {
    struct stat buf;
    int i = stat (fileName, &buf);
    if (i == 0) {
        return 1;
    }
    return 0;
}


/*    Main function    */


int main() {

    char buff[100] = "";
    char str[100] = "";
    int i = 0;

    time_t now;

    strcpy(datetime, "");
    pdf_file_size = 0;

    strcpy(fax_folder, "/var/spool/asterisk/faxes");
    strcpy(from_sender, "");

    AGITool_Init(&agi);

    AGITool_verbose(&agi, &res, "", 0);
    AGITool_verbose(&agi, &res, "MOR Fax2Email AGI script started.", 0);

    // DB connection
    read_config();

    if (!mysql_connect()) {
        AGITool_verbose(&agi, &res, "ERROR! Not connected to database.", 0);
        AGITool_Destroy(&agi);
        return 0;
    } else {
        AGITool_verbose(&agi, &res, "Successfully connected to database.", 0);
    }

    // get variables from dialplan
    AGITool_get_variable2(&agi, &res, "FROM_SENDER", from_sender, sizeof(from_sender));
    AGITool_get_variable2(&agi, &res, "FAXFILE", fax_file_name, sizeof(fax_file_name));
    AGITool_get_variable2(&agi, &res, "FAXSENDER", fax_sender, sizeof(fax_sender));
    AGITool_get_variable2(&agi, &res, "MOR_FAX_ID", buff, sizeof(buff));
    fax_device_id = atoi(buff);

    sprintf(pdf_file, "%s/%s.pdf", fax_folder, fax_file_name);
    sprintf(tif_file, "%s/%s.tif", fax_folder, fax_file_name);

    sprintf(str, "from sender: %s, fax file: %s, faxsender: %s, fax_id :%i, pdf file: %s, tif file: %s", from_sender, fax_file_name, fax_sender, fax_device_id, pdf_file, tif_file);
    AGITool_verbose(&agi, &res, str, 0);

    // date-time
    if (time(&now) != (time_t)(-1)) {
        struct tm *mytime = localtime(&now);
        if (mytime) {
            strftime(datetime, sizeof datetime, "%Y-%m-%d %T", mytime);
        }
    }   

    // check if file exists
    if (!file_exists(tif_file)){    
        // mark this fax call as bad one
        sprintf(sqlcmd, "INSERT INTO pdffaxes (device_id, filename, receive_time, size, deleted, uniqueid, fax_sender, status) VALUES ('%i', '', '%s', '0', '1', '%s', '%s', 'no_tif');", fax_device_id, datetime, fax_file_name, fax_sender);
        mysql_query(&mysql, sqlcmd);
        AGITool_verbose(&agi, &res, "ERROR! TIF file does not exist!", 0);
        AGITool_Destroy(&agi);
        mysql_close(&mysql);  
        return 0;
    }

    // convert2pdf
    sprintf(systcmd, "/usr/bin/tiff2pdf -o %s %s", pdf_file, tif_file);
    system(systcmd);

    // file size    
    pdf_file_size = FileSize(pdf_file);

    // check if file size > 0
    if (pdf_file_size == 0) {    
        // mark this fax call as unsucsefull
        sprintf(sqlcmd, "INSERT INTO pdffaxes (device_id, filename, receive_time, size, deleted, uniqueid, fax_sender, status) VALUES ('%i', '', '%s', '0', '1', '%s', '%s', 'pdf_size_0');", fax_device_id, datetime, fax_file_name, fax_sender);
        mysql_query(&mysql, sqlcmd);
        AGITool_verbose(&agi, &res, "ERROR! PDF file size == 0!", 0);
        AGITool_Destroy(&agi);
        mysql_close(&mysql);  
        return 0;
    }

    // insert into db record about sucessful FAX call - received TIF -> PDF
    sprintf(sqlcmd, "INSERT INTO pdffaxes (device_id, filename, receive_time, size, deleted, uniqueid, fax_sender) VALUES ('%i', '%s.pdf', '%s', '%i', '0', '%s', '%s');", fax_device_id, fax_file_name, datetime, pdf_file_size, fax_file_name, fax_sender);
    mysql_query(&mysql, sqlcmd);

    get_owner_id();
    get_emails();

    if (total_emails > 0) {

        sprintf(str, "Found %i emails, user_id: %i, owner_id: %d, pdffax_id: %i, from_sender_db: %s, mail_server: %s, mail username: %s, mail psw: %s, mail port: %i", total_emails, user_id, fax_device_owner_id, pdffax_id, from_sender_db, mail_server, mail_username, mail_password, mail_port);
        AGITool_verbose(&agi, &res, str, 0);

        // format from email
        if ((strlen(from_sender) == 0) && (strlen(from_sender_db) > 0)) {
            strcpy(from_sender, from_sender_db);
        }

        // format email server auth string
        strcpy(mail_server_line, "");

        // with login
        if ((strlen(mail_server)) && (strlen(mail_username))) {
            sprintf(mail_server_line, "tls=auto -s %s:%i -xu %s -xp %s", mail_server, mail_port, mail_username, mail_password);
        } else {
            // without login
            if (strlen(mail_server)) {
                sprintf(mail_server_line, "tls=auto -s %s:%i", mail_server, mail_port);
            }
        }

    } else {

        AGITool_verbose(&agi, &res, "ERROR! No emails found.", 0);
        AGITool_Destroy(&agi);
        mysql_close(&mysql);  
        return 0; 

    }

    // send emails
    AGITool_verbose(&agi, &res, "Sent to:", 0);

    for (i = 0; i < total_emails; i++) {

        sprintf(systcmd, "/usr/local/mor/sendEmail -f %s -t %s -u 'Fax from %s' -m 'Fax from %s' -a %s -o %s", from_sender, emails[i].email, fax_sender, fax_sender, pdf_file, mail_server_line);
        my_debug(systcmd);
        system(systcmd);

        AGITool_verbose(&agi, &res, emails[i].email, 0);    

        // insert into db some actions
        sprintf(sqlcmd, "INSERT INTO actions (user_id, date, action, data, data2) VALUES ('%i', '%s', 'fax2email', '%i', '%s');", user_id, datetime, pdffax_id, emails[i].email);
        mysql_query(&mysql, sqlcmd);

    }

    AGITool_verbose(&agi, &res, "MOR Fax2Email AGI script stopped.", 0);
    AGITool_verbose(&agi, &res, "", 0);

    AGITool_Destroy(&agi);
    mysql_close(&mysql);

    return 0;
}


/*    Functions    */


int get_emails() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char sqlcmd[2048] = "";
    int i;    

    sprintf(sqlcmd, "SELECT email, users.id, "
                    "(SELECT id FROM pdffaxes WHERE uniqueid = '%s' LIMIT 1), "
                    "(select value from conflines where name = 'Email_Fax_From_Sender' and owner_id = %d LIMIT 1), "
                    "(select value from conflines where name = 'Email_Smtp_Server' and owner_id = %d LIMIT 1), "
                    "(select value from conflines where name = 'Email_Login' and owner_id = %d LIMIT 1), "
                    "(select value from conflines where name = 'Email_Password' and owner_id = %d LIMIT 1), "
                    "(select value from conflines where name = 'Email_port' and owner_id = %d LIMIT 1) "
                    "FROM pdffaxemails, users, devices "
                    "WHERE devices.id = %d AND users.id = devices.user_id AND devices.id = pdffaxemails.device_id", 
                    fax_file_name, fax_device_owner_id, fax_device_owner_id, fax_device_owner_id, fax_device_owner_id, fax_device_owner_id, fax_device_id);

    
    if (mysql_query(&mysql,sqlcmd)) {
        return 1;
    }

    result = mysql_store_result(&mysql);

    if (result)  {

        i = 0;

        while (( row = mysql_fetch_row(result) )) {

            if (row[0]) {
                strcpy(emails[i].email, row[0]);
                i++;
            }

            if (row[1]) user_id = atoi(row[1]); else user_id = 0;
            if (row[2]) pdffax_id = atoi(row[2]); else pdffax_id = 0;
            if (row[3]) strcpy(from_sender_db, row[3]); else strcpy(from_sender_db, "");
            if (row[4]) strcpy(mail_server, row[4]); else strcpy(mail_server, "");
            if (row[5]) strcpy(mail_username, row[5]); else strcpy(mail_username, "");
            if (row[6]) strcpy(mail_password, row[6]); else strcpy(mail_password, "");
            if (row[7]) mail_port = atoi(row[7]); else mail_port = 25;

        }
    }

    total_emails = i;
    mysql_free_result(result);
        
    return 0;

}


int get_owner_id() {

    MYSQL_RES *result;
    MYSQL_ROW row;

    char sqlcmd[2048] = "";

    sprintf(sqlcmd, "SELECT owner_id FROM users JOIN devices ON devices.user_id = users.id WHERE devices.id = %d LIMIT 1", fax_device_id);

    if (mysql_query(&mysql,sqlcmd)) {
        return 1;
    }

    result = mysql_store_result(&mysql);

    if (result)  {
        while ((row = mysql_fetch_row(result))) {
            if (row[0]) {
                fax_device_owner_id = atoi(row[0]);
            }
        }
    }

    mysql_free_result(result);

    return 0;

}


void read_config() {

    FILE *file;
    char var[200] = "", val[200] = "";

    file = fopen("/var/lib/asterisk/agi-bin/mor.conf", "r");

    /* Default values */
    strcpy(dbhost, "localhost");
    strcpy(dbname, "mor");
    strcpy(dbuser, "mor");
    strcpy(dbpass, "mor");
    dbport = 3306;

    /* Read values from conf file */    
    while (fscanf(file, "%s = %s", var, val) != EOF) {

        if (!strcmp(var, "host")) {
            strcpy(dbhost, val);
        }
        if (!strcmp(var, "db")) {
            strcpy(dbname, val);
        }
        if (!strcmp(var, "user")) {
            strcpy(dbuser, val);
        }
        if (!strcmp(var, "secret")) {
            strcpy(dbpass, val);
        }
        if (!strcmp(var, "port")) {
            dbport = atoi(val);
        }

    }

    fclose(file);

}


int mysql_connect() {

    if (strlen(dbhost) && strlen(dbuser) && strlen(dbpass) && strlen(dbname)) {

        if (!mysql_init(&mysql)) {
            AGITool_verbose(&agi, &res, "Insufficient memory to allocate MySQL resource.", 0);
            return 0;
        }

        if (mysql_real_connect(&mysql, dbhost, dbuser, dbpass, dbname, dbport, NULL, 0)) {
            return 1;
        } else {
            AGITool_verbose(&agi, &res, "Failed to connect database server. Check debug for more info.", 0);
            return 0;
        }

    } else {

        if (mysql_ping(&mysql) != 0) {
            AGITool_verbose(&agi, &res, "Failed to reconnect. Check debug for more info.", 0);
            return 0;
        }

        if (mysql_select_db(&mysql, dbname) != 0) {
            AGITool_verbose(&agi, &res, "Database Select Failed", 0);
            return 0;
        }

        AGITool_verbose(&agi, &res, "DB connected.", 0);
        return 1;

    }
}
