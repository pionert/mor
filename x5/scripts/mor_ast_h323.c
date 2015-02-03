/*
*
*    MOR Asterisk H323 configuration generation script
*    Copyright Mindaugas Kezys / Kolmisoft 2009-2014
*
*    v0.1.5
*
*       2014-11-28 v0.1.5 - bugfix for h323 and extensions reload
*       2012-11-29 v0.1.4 - Do not create port setting if port is 0, this allows incoming calls from all ports #6879
*       2009.02.11 v0.1.3 - Codec support
*       2009.02.06 v0.1.2 - Provider name = prov+device.id
*       2009.01.23 v0.1.1 - CallerID support
*/


#define SCRIPT_VERSION   "1.5"
#define SCRIPT_NAME      "mor_ast_h323"
#define EXTENSIONS_FILE  "/etc/asterisk/extensions_mor_h323.conf"
#define ALLOW_MULTIPLE   1      // allow to run multiple script instances at the same time

#include "mor_functions.c"

/* Variables */

int h323 = -1;

/* Function declarations */

int generate_h323_server_configuration();
int generate_h323_device_configuration();
void device_codecs(char *codecs_string, int device_id);

int main(int argc, char *argv[]) {

    mor_init("Starting MOR H323 reload script\n");

    // check if script is executed with arguments
    // if argument is 'h323', it mean that script is executed from /etc/asterisk/h323.conf and only devices should be generated
    // if argument is 'h323_extensions', it means that script is executed from /etc/asterisk/extensions_mor_h323.conf and only extensions should be generated
    // if arguments are not supplied, then h323 variables is -1 and it will work as it used to work before 1.5 version (but i will have bug http://trac.kolmisoft.com/trac/ticket/10748)
    if (argc > 1) {
        if (strcmp(argv[1], "h323") == 0) {
            h323 = 1;
        } else if (strcmp(argv[1], "h323_extensions") == 0) {
            h323 = 2;
        }
    }

    mor_log("H323 = %d\n", h323);

    generate_h323_server_configuration();
    generate_h323_device_configuration();
    mysql_close(&mysql);

    mor_log("Script completed\n");

}


/* Functions */


int generate_h323_server_configuration() {

    MYSQL_RES *result;
    MYSQL_ROW row;
    char sqlcmd[2048] = "";
    int device_id = 0;
    char buff[2048] = "";
    char codecs_string[2048] = "";

    sprintf(buff, "\n; =========== MOR H323 Provider configuration ============\n");
    printf(buff);

    sprintf(sqlcmd, "SELECT providers.name, providers.id, devices.id, devices.host, devices.port, devices.faststart, devices.h245tunneling, devices.dtmfmode, devices.name "
        "FROM devices JOIN providers ON (providers.device_id = devices.id) WHERE providers.tech = 'H323'");

    if (mor_mysql_query(sqlcmd)) {
        return 1;
    } else {
        result = mysql_store_result(&mysql);
        if (result) {
            while ((row = mysql_fetch_row(result))) {
                sprintf(buff, "");
                sprintf(buff, "\n;Provider id: %s, name: %s\n;Device id: %s\n[%s]\ntype=peer\nhost=%s\n", row[1], row[0], row[2], row[8], row[3]);

                // no info about port if port = 0
                if (atoi(row[4])) {
                    sprintf(buff, "%sport=%s\n", buff, row[4]);
                }

                sprintf(buff, "%sfastStart=%s\nh245Tunneling=%s\ndtmfmode=%s\n", buff, row[5], row[6], row[7]);

                if (row[2]) {
                    device_id = atoi(row[2]);
                } else {
                    device_id = 0;
                }

                device_codecs(codecs_string, device_id);
                sprintf(buff, "%s%s", buff, codecs_string);
                // output to asterisk
                printf(buff);
            }
            mysql_free_result(result);
        }
    }

    return 0;

}


int generate_h323_device_configuration() {

    MYSQL_RES *result;
    MYSQL_ROW row;
    char sqlcmd[2048] = "";
    int device_id = 0;
    char codecs_string[2048] = "";
    char buff[2048] = "";

    FILE *file;

    if (h323 == -1) {
        file = fopen(EXTENSIONS_FILE, "w");
    }

    sprintf(buff, "\n; =========== MOR H323 Device configuration ============\n");

    if (h323 == -1) {
        fprintf(file, "%s\n", buff);
    } else {
        printf("%s\n", buff);
    }

    sprintf(sqlcmd, "SELECT devices.name, devices.id, devices.host, devices.port, devices.faststart, devices.h245tunneling, devices.dtmfmode, devices.callerid "
        "FROM devices WHERE devices.device_type = 'H323' and devices.user_id != -1");


    if (mor_mysql_query(sqlcmd)) {
        return 1;
    } else  {
        result = mysql_store_result(&mysql);
        if (result) {
            while ((row = mysql_fetch_row(result))) {

                // make Asterisk configuration

                sprintf(buff, "");
                sprintf(buff, "\n;Device id: %s\n[%s]\ntype=friend\nhost=%s\n", row[1], row[0], row[2]);

                // no info about port if port = 0
                if (atoi(row[3])) {
                    sprintf(buff, "%sport=%s\n", buff, row[3]);
                }

                sprintf(buff, "%sfastStart=%s\nh245Tunneling=%s\ndtmfmode=%s\ncontext=h323_%s\n", buff, row[4], row[5], row[6], row[1]);

                if (row[1]) {
                    device_id = atoi(row[1]);
                } else {
                    device_id = 0;
                }

                device_codecs(codecs_string, device_id);
                sprintf(buff, "%s%s", buff, codecs_string);
                // output to asterisk
                if (h323 == -1 || h323 == 1) {
                    printf(buff);
                }

                // make Asterisk extensions.conf configuration

                sprintf(buff, "");
                if ((row[7]) && (strlen(row[7]))) {
                    sprintf(buff, "\n[h323_%s]\nexten => _X.,1,Set(CDR(ACCOUNTCODE)=%s)\nexten => _X.,2,Set(CALLERID(all)=%s)\nexten => _X.,3,Goto(mor,${EXTEN},1)\n", row[1], row[1], row[7]);
                } else {
                    sprintf(buff, "\n[h323_%s]\nexten => _X.,1,Set(CDR(ACCOUNTCODE)=%s)\nexten => _X.,2,Goto(mor,${EXTEN},1)\n", row[1], row[1]);
                }

                if (h323 == -1) {
                    fprintf(file, "%s\n", buff);
                } else if (h323 == 2) {
                    printf("%s\n", buff);
                }
            }
            mysql_free_result(result);
        }
    }

    if (h323 == -1) {
        fclose(file);
    }

    return 0;

}


void device_codecs(char *codecs_string, int device_id) {

    MYSQL_RES *result;
    MYSQL_ROW row;
    char sqlcmd[2048] = "";
    char buff[2048] = "disallow=all\n";

    // ================= codecs ==================

    sprintf(sqlcmd, "SELECT codecs.name FROM codecs JOIN devicecodecs ON (devicecodecs.codec_id = codecs.id AND devicecodecs.device_id = %i)", device_id);

    if (mor_mysql_query(sqlcmd)) {
        return;
    } else {
        result = mysql_store_result(&mysql);
        if (result) {
            while ((row = mysql_fetch_row(result))) {
                sprintf(buff, "%sallow=%s\n", buff, row[0]);
            }
            mysql_free_result(result);
        }
    }
    strcpy(codecs_string, buff);

}
