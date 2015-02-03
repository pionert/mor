/*
*
*	MOR UseVoucher AGI script
*	Copyright Mindaugas Kezys / Kolmisoft 2011-2014
*
* 	v1.14
*

*   2014-11-07  v1.14   END IVR 9 skip intro
*   2014-10-24  v1.13   END IVR 9 sound files
*	2013-10-10	v1.12	Topup works with pin touched functionality
*	2013-04-20	v1.11	Topup another card by PIN + NUM
*	2012-12-20	v1.10	Bugfix to currency retrieval
*	2012-12-14	v1.9	Bugfix to disable searching by CLI all the time, allow search by PIN also
*	2012-10-21	v1.8	Announce by audio that this is Calling Card Topup for user to know
*	2012-06-30	v1.7	Tune to Actions to DB
*	2012-06-28	v1.6	Search by CallerID from DialPlan
*	2012-06-27	v1.5	Bugfix to 1.4, update CallerID not only after CallerID enter, but also after PIN enter
*	2012-06-27	v1.4	Update CallerID right after CardA is found, no need to find CardB
* 	2012-06-19	v1.3	Topup another card by PIN or CallerID
*	2012-06-19	v1.2	Allow not to tell balance by Set(MOR_TOPUP_NO_TELL_BALANCE=1)
* 	2012-06-17	v1.1	Bugfix - do not allow to use card for topup if it has active call + more debug
* 	2011-08-21	v1.0
*
*	This AGI top-ups Card's balance with another card's balance
*/


/*

    Function: Card Top-Up
	CardA balance is increased by CardB balance. And CardB balance = 0.


    Searching for CardA:

        By default program searches for CardA by MOR_CARD_ID.

	If MOR_TOPUP_CC_CLI length > 0, then we search by this CallerID provider from DialPlan
	    This is used when we send CallerID from DialPlan

	If MOR_TOPUP_CC_BY_CLI == 1 then it asks to enter CallerID, searches Card by CallerID.
	    If CardA is ok, proceeds to search CardB.
	    If CardA is not ok (not found, not sold, not valid, etc) it searches for CardA by PIN.
	    This is used when we ask to enter CallerID by DTMF

	If MOR_TOPUP_CC_BY_PIN == 1 OR CardA not found by CallerID,
	    then system asks to enter PIN and searches for CardA by PIN
	    If CardA is found by PIN, proceeds to search for CardB
	    If CardA is not found by PIN or CardA is not OK, then aborts.

	If MOR_TOPUP_CC_BY_PINNUM == 1 OR CardA not found by CallerID,
	    then system asks to enter PIN + NUM and searches for CardA by PIN + NUM
	    If CardA is found by PIN + NUM, proceeds to search for CardB
	    If CardA is not found by PIN + NUM or CardA is not OK, then aborts.

	When CardA is found and CallerID is entered - CallerID is changed for CardA

    Searching for CardB

	System asks to enter PIN and searches for CardB by PIN.
	    If CardB is not found or not ok - asks to enter new PIN for CardB searc.
	    If CardB is OK, then CardA.balance += CardB.balance, CardB.balance = 0

	    Speacial case: If we tried to enter CallerID to look for CardA then CardA.callerid = CallerID we entered in first step.

*/


#include <stdio.h>
#include <stdarg.h>
#include <mysql.h>
#include <mysql/errmsg.h>
#include <time.h>
#include <sys/stat.h>
#include <math.h>


#include "mor_agi_functions.c"


void mor_get_taxes(int card_id);
float mor_count_taxes(float amount);
float mor_deduct_taxes(float amount_with_taxes);


/* taxes */
int tax_compound = 0;
//int tax1_enabled; // tax1 is always enabled
int tax2_enabled = 0;
int tax3_enabled = 0;
int tax4_enabled = 0;
float tax1_value = 0;
float tax2_value = 0;
float tax3_value = 0;
float tax4_value = 0;

MYSQL_RES   *result;
MYSQL_ROW   row;



/*	Main function	*/

int main(int argc, char *argv[])
{
    char buff[4096];
    char str[4096];
    int i;

    time_t now;


    char *variable;
    char *value;


    // variables

    int owner_id = 0;

    double card_balance = 0.0;
    double cardA_balance = 0.0;


    char currency[10] = "";
    double exchange_rate;

    //----------------

    char card_pin[100] = "";
    char card_number[100] = "";
    char card_cli[100] = "";

    double ghost_balance_perc = 100;
    int got_card = 0;

    int cardA_id = 0;
    int cardB_id = 0;

    int cardA_valid1 = 0;
    int cardA_valid2 = 0;
    // cardB
    int valid1 = 0;
    int valid2 = 0;

    int cardA_sold = 0;
    int cardB_sold = 0;
    char cardB_first_use[128] = "";

    int pin_touch_functionality = 0;
    int charge_distributor = 0;

    int retries;

    int cardB_calls = 0;
    double cardB_card_price = 0;
    int cardB_distributor_id = 0;
    int cardB_distributor_postpaid = 0;
    double cardB_distributor_balance = 0;
    double cardB_distributor_credit = 0;

    int tell_balance = 1;

    /* topup by PIN another card */
    int cc_by_pin = 0;
    /* topup by PIN and NUMBER another card */
    int cc_by_pin_num = 0;
    /* topup by CallerID another card, ask PIN if not found by CallerID (CLI), if found by PIN - assign this CallerID to that Card */
    int cc_by_cli = 0;

    int end_ivr_9 = 0;

    //----------------



    AGITool_Init(&agi);

    AGITool_verbose(&agi, &res, "", 0);
    AGITool_verbose(&agi, &res, "MOR Card-Topup AGI script started.", 0);


    // DB connection
    read_config();

    // sprintf(str, "Host: %s, dbname: %s, user: %s, psw: %s, port: %i", dbhost, dbname, dbuser, dbpass, dbport);
    // AGITool_verbose(&agi, &res, str, 0);

    if (!mysql_connect()) {

        AGITool_verbose(&agi, &res, "ERROR! Not connected to database.", 0);
        AGITool_Destroy(&agi);
        return 0;
    } else {
        //AGITool_verbose(&agi, &res, "Successfully connected to database.", 0);
    }


    // why asnwer here? - to be ready to play msg and receive dtmfs
    AGITool_answer(&agi, &res);



    // Card ID

    AGITool_get_variable2(&agi, &res, "MOR_CARD_ID", buff, sizeof(buff));
    if (buff) {
        cardA_id = atoi(buff);

        sprintf(str, "Card ID: %i", cardA_id);
        AGITool_verbose(&agi, &res, str, 0);
    }


    AGITool_get_variable2(&agi, &res, "MOR_TOPUP_NO_TELL_BALANCE", buff, sizeof(buff));
    if (buff) {
        tell_balance = !atoi(buff);

        sprintf(str, "Tell balance: %i", tell_balance);
        AGITool_verbose(&agi, &res, str, 0);
    }

    AGITool_get_variable2(&agi, &res, "MOR_TOPUP_CC_BY_PIN", buff, sizeof(buff));
    if (buff) {
        cc_by_pin = atoi(buff);

        sprintf(str, "Search Card by PIN: %i", cc_by_pin);
        AGITool_verbose(&agi, &res, str, 0);
    }

    AGITool_get_variable2(&agi, &res, "MOR_TOPUP_CC_BY_PINNUM", buff, sizeof(buff));
    if (buff) {
        cc_by_pin_num = atoi(buff);

        sprintf(str, "Search Card by PIN and NUMBER: %i", cc_by_pin_num);
        AGITool_verbose(&agi, &res, str, 0);
    }

    AGITool_get_variable2(&agi, &res, "MOR_TOPUP_CC_BY_CLI", buff, sizeof(buff));
    if (buff) {
        cc_by_cli = atoi(buff);

        sprintf(str, "Search Card by CallerID: %i", cc_by_cli);
        AGITool_verbose(&agi, &res, str, 0);
    }


    AGITool_get_variable2(&agi, &res, "MOR_TOPUP_CC_CLI", buff, sizeof(buff));
    if (buff) {
        strcpy(card_cli, buff);

        // seach by cli
        if (strlen(card_cli)) {
            cc_by_cli = 1;

            sprintf(str, "Search Card by CallerID: %s", card_cli);
            AGITool_verbose(&agi, &res, str, 0);
        }
    }

    AGITool_get_variable2(&agi, &res, "MOR_END_IVR_9", buff, sizeof(buff));
    if (buff) {
        end_ivr_9 = atoi(buff);

        if (end_ivr_9) {
            sprintf(str, "END IVR 9: %i", end_ivr_9);
            AGITool_verbose(&agi, &res, str, 0);
        }
    }

    sprintf(sqlcmd, "SELECT name, value FROM `conflines` WHERE name = 'Charge_Distributor_on_first_use'");

    if (mysql_query(&mysql, sqlcmd)) {

        sprintf(str, "Warning: %i", mysql_error(&mysql));
        AGITool_verbose(&agi, &res, str, 0);

    } else {

        result = mysql_store_result(&mysql);
        if (result == NULL) {
            return 1;
        }

        while ((row = mysql_fetch_row(result))) {
            if (row[0]) {
                if (strcmp("Charge_Distributor_on_first_use", row[0]) == 0) {
                    if (row[1]) pin_touch_functionality = atoi(row[1]);
                }
            }
        }

        mysql_free_result(result);

    }

    sprintf(str, "Charge Distributor on first use: %i", pin_touch_functionality);
    AGITool_verbose(&agi, &res, str, 0);

    // read card A data
    got_card = 0;




    // play intro
    if (end_ivr_9 == 0) {
        AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/calling_card_topup");
    }



    AGITool_verbose(&agi, &res, "Searching for Card A which balance will be increased by topup", 0);



    if (cc_by_cli) {


        AGITool_verbose(&agi, &res, "cc_by_cli > 0", 0);

        if (strlen(card_cli)) {

            // we have card_cli from dial plan

        } else {
            // ask card callerid
            AGITool_get_data(&agi, &res, "mor/ivr_voices/cc_please_enter_callerid_number", 10000, 30);

            strcpy(card_cli, res.result);
            sprintf(str, "Primary Card CallerID entered: %s", card_cli);
            AGITool_verbose(&agi, &res, str, 0);
        }


        if (!strlen(card_cli)) {
            AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_you_have_entered_nothing");

            got_card = 0;

        } else {


            // ------- get card details -----


            sprintf(sqlcmd, "SELECT cards.id, cards.balance, cards.sold, ((NOW() >= cardgroups.valid_from) AND (NOW() <= cardgroups.valid_till)),  (ISNULL(first_use) OR (valid_after_first_use = 0) OR (DATE_ADD(first_use, INTERVAL valid_after_first_use DAY) >= NOW())) FROM cards JOIN cardgroups ON (cards.cardgroup_id = cardgroups.id) WHERE cards.callerid = '%s' LIMIT 1;", card_cli);

            //	sprintf(str, "SQL: %s", sqlcmd);
            //	AGITool_verbose(&agi, &res, str, 0);

            if (mysql_query(&mysql,sqlcmd)) {
                // error
                //res = -1;
            } else {
                // query succeeded, process any data returned by it
                result = mysql_store_result(&mysql);
                if (result) {
                    // there are rows
                    //i = 0;
                    while ((row = mysql_fetch_row(result))) {
                        if (row[0]) cardA_id = atoi(row[0]);
                        if (row[1]) cardA_balance = atof(row[1]);
                        if (row[2]) cardA_sold = atoi(row[2]);
                        if (row[3]) cardA_valid1 = atoi(row[3]);
                        if (row[4]) cardA_valid2 = atoi(row[4]);

                        got_card = 1;
                    }
                    mysql_free_result(result);
                }
            }


        } // got pin



        if (got_card) {

            sprintf(str, "Primary Card ID: %i, balance: %f, sold: %i, valid1: %i, valid2: %i", cardA_id, cardA_balance, cardA_sold, cardA_valid1, cardA_valid2);
            AGITool_verbose(&agi, &res, str, 0);


            // check for valid periods
            if ((!cardA_valid1)||(!cardA_valid2)) {

                AGITool_verbose(&agi, &res, "Card not valid, cannot use for Top-Up", 0);

                AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_expired");
                got_card = 0;
            }


            // check for sold
            if (!cardA_sold) {

                AGITool_verbose(&agi, &res, "Card not sold, cannot use for Top-Up", 0);

                AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_is_not_sold_yet");
                got_card = 0;
            }


        } else {

            AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_not_found");

        }


        if (got_card) {
            AGITool_exec(&agi, &res, "PLAYBACK", "mor/mor_thank_you");





        } else {

            /* search card A by pin */
            cc_by_pin = 1;
        }

    }


    if (!got_card)
        if (cc_by_pin || cc_by_pin_num) {


            /* searching primary card (which balance we want to increase) by asking to enter PIN */

            retries = 0;
            do {

                int got_card_number = 0;
                char sql_card_number[256] = { 0 };

                if (cc_by_pin_num == 1) {
                    // ask voucher number
                    AGITool_get_data(&agi, &res, "mor/ivr_voices/cc_enter_card_number", 10000, 30);

                    strcpy(card_number, res.result);
                    sprintf(str, "Primary Card number entered: %s", card_number);
                    AGITool_verbose(&agi, &res, str, 0);

                    if (strlen(card_number)) {
                        got_card_number = 1;
                    }

                }

                if (got_card_number == 1 || cc_by_pin_num == 0) {
                    // ask voucher pin
                    if (end_ivr_9) {
                        AGITool_get_data(&agi, &res, "mor/ivr_voices/cc_enter_pin_to_topup", 10000, 30);
                    } else {
                        AGITool_get_data(&agi, &res, "mor/ivr_voices/cc_enter_pin", 10000, 30);
                    }

                    strcpy(card_pin, res.result);
                    sprintf(str, "Primary Card PIN entered: %s", card_pin);
                    AGITool_verbose(&agi, &res, str, 0);
                } else {
                    memset(card_pin, 0, strlen(card_pin));
                }

                if (!strlen(card_pin)) {

                    AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_you_have_entered_nothing");
                    got_card = 0;

                } else {

                    // got pin

                    // ------- get card details -----

                    if (got_card_number == 1) {
                        sprintf(sql_card_number, " AND cards.number = '%s' ", card_number);
                    }


                    sprintf(sqlcmd, "SELECT cards.id, cards.balance, cards.sold, ((NOW() >= cardgroups.valid_from) AND (NOW() <= cardgroups.valid_till)),  (ISNULL(first_use) OR (valid_after_first_use = 0) OR (DATE_ADD(first_use, INTERVAL valid_after_first_use DAY) >= NOW())) FROM cards JOIN cardgroups ON (cards.cardgroup_id = cardgroups.id) WHERE cards.pin = '%s' %s LIMIT 1;", card_pin, sql_card_number);

                    //	sprintf(str, "SQL: %s", sqlcmd);
                    //	AGITool_verbose(&agi, &res, str, 0);

                    if (mysql_query(&mysql,sqlcmd)) {
                        // error
                        //res = -1;
                    } else {
                        // query succeeded, process any data returned by it
                        result = mysql_store_result(&mysql);
                        if (result) {
                            // there are rows
                            //i = 0;
                            while ((row = mysql_fetch_row(result))) {
                                if (row[0]) cardA_id = atoi(row[0]);
                                if (row[1]) cardA_balance = atof(row[1]);
                                if (row[2]) cardA_sold = atoi(row[2]);
                                if (row[3]) cardA_valid1 = atoi(row[3]);
                                if (row[4]) cardA_valid2 = atoi(row[4]);

                                got_card = 1;
                            }
                            mysql_free_result(result);
                        }
                    }


                } // got pin



                if (got_card) {

                    sprintf(str, "Primary Card ID: %i, balance: %f, sold: %i, valid1: %i, valid2: %i", cardA_id, cardA_balance, cardA_sold, cardA_valid1, cardA_valid2);
                    AGITool_verbose(&agi, &res, str, 0);


                    // check for valid periods
                    if ((!cardA_valid1)||(!cardA_valid2)) {

                        AGITool_verbose(&agi, &res, "Card not valid, cannot use for Top-Up", 0);

                        AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_expired");
                        got_card = 0;
                    }


                    // check for sold
                    if (!cardA_sold) {

                        AGITool_verbose(&agi, &res, "Card not sold, cannot use for Top-Up", 0);

                        AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_is_not_sold_yet");
                        got_card = 0;
                    }


                } else {

                    AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_not_found");

                }



                retries += 1;
            } while ((!got_card)&&(retries < 3));


            if (got_card) {
                AGITool_exec(&agi, &res, "PLAYBACK", "mor/mor_thank_you");





            }

        } else {

            // search by ID
            if (cardA_id) {
                got_card = 1;
            }

        } // searching for cardA



    if (got_card) {


        // get currency details

        sprintf(sqlcmd, "SELECT currencies.name, currencies.exchange_rate, ghost_balance_perc, cardgroups.owner_id FROM cards JOIN cardgroups ON (cards.cardgroup_id = cardgroups.id) JOIN currencies ON (cardgroups.tell_balance_in_currency = currencies.name) WHERE cards.id = '%i' LIMIT 1;", cardA_id);

        //sprintf(str, "SQL: %s", sqlcmd);
        //AGITool_verbose(&agi, &res, str, 0);

        if (mysql_query(&mysql,sqlcmd)) {
            // error
            //res = -1;
        } else {
            // query succeeded, process any data returned by it
            result = mysql_store_result(&mysql);
            if (result) {
                // there are rows
                //i = 0;
                while ((row = mysql_fetch_row(result))) {

                    if (row[0]) strcpy(currency, row[0]);
                    if (row[1]) exchange_rate = atof(row[1]);
                    if (row[2]) ghost_balance_perc = atof(row[2]);
                    if (row[3]) owner_id = atof(row[3]);

                    sprintf(str, "Primary Card found! Currency: %s, exchange_rate: %f, ghost_balance_perc: %f, owner_id: %i", currency, exchange_rate, ghost_balance_perc, owner_id);
                    AGITool_verbose(&agi, &res, str, 0);


                    //got_card = 1;
                }
                mysql_free_result(result);
            }
        }


    }



    if (!got_card) {

        // break
        AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_not_found");

        mysql_close(&mysql);
        AGITool_Destroy(&agi);
        return 1;


    } else {


        // ================= update card's A Callerid ==============

        if (strlen(card_cli)) {
            sprintf(sqlcmd, "UPDATE cards SET callerid = '%s' WHERE cards.id = %i;", card_cli, cardA_id);
            mysql_query(&mysql,sqlcmd);
        }


    }








    // continue
    got_card = 0;





    /* searching for card which balance will be used for topup */


    AGITool_verbose(&agi, &res, "Searching for Card B which balance will be used for topup", 0);


    retries = 0;
    do {

        cardB_id = 0;
        int got_card_number = 0;
        char sql_card_number[256] = { 0 };

        if (cc_by_pin_num == 1) {
            // ask voucher number
            AGITool_get_data(&agi, &res, "mor/ivr_voices/cc_enter_card_number", 10000, 30);

            strcpy(card_number, res.result);
            sprintf(str, "Card number entered: %s", card_number);
            AGITool_verbose(&agi, &res, str, 0);

            if (strlen(card_number)) {
                got_card_number = 1;
            }

        }

        if (got_card_number == 1 || cc_by_pin_num == 0) {
            // ask voucher pin
            if (end_ivr_9) {
                AGITool_get_data(&agi, &res, "mor/ivr_voices/cc_enter_pin_to_take_topup", 10000, 30);
            } else {
                AGITool_get_data(&agi, &res, "mor/ivr_voices/cc_enter_pin", 10000, 30);
            }

            strcpy(card_pin, res.result);
            sprintf(str, "Card PIN entered: %s", card_pin);
            AGITool_verbose(&agi, &res, str, 0);
        } else {
            memset(card_pin, 0, strlen(card_pin));
        }


        if (!strlen(card_pin)) {

            AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_you_have_entered_nothing");
            got_card = 0;

        } else {

            if (got_card_number == 1) {
                sprintf(sql_card_number, " AND cards.number = '%s' ", card_number);
            }

            // got pin

            // ------- get card details -----


            sprintf(sqlcmd, "SELECT cards.id, cards.balance, cards.sold, ((NOW() >= cardgroups.valid_from) AND (NOW() <= cardgroups.valid_till)), (ISNULL(first_use) OR (valid_after_first_use = 0) OR (DATE_ADD(first_use, INTERVAL valid_after_first_use DAY) >= NOW())), COUNT(activecalls.id), cards.first_use, cards.user_id, distr.balance, cardgroups.price, distr.postpaid, distr.credit FROM cards JOIN cardgroups ON (cards.cardgroup_id = cardgroups.id) LEFT JOIN activecalls ON ( cards.id = activecalls.card_id ) LEFT JOIN users AS distr ON distr.id = cards.user_id WHERE cards.pin = '%s' %s LIMIT 1;", card_pin, sql_card_number);

            // sprintf(str, "SQL: %s", sqlcmd);
            // AGITool_verbose(&agi, &res, str, 0);

            if (mysql_query(&mysql,sqlcmd)) {
                // error
                // res = -1;
            } else {
                // query succeeded, process any data returned by it
                result = mysql_store_result(&mysql);
                if (result) {
                    // there are rows
                    // i = 0;
                    while ((row = mysql_fetch_row(result))) {
                        if (row[0]) cardB_id = atoi(row[0]);
                        if (row[1]) card_balance = atof(row[1]);
                        if (row[2]) cardB_sold = atoi(row[2]);
                        if (row[3]) valid1 = atoi(row[3]);
                        if (row[4]) valid2 = atoi(row[4]);
                        if (row[5]) cardB_calls = atoi(row[5]);
                        if (row[6]) strcpy(cardB_first_use, row[6]); else strcpy(cardB_first_use, "");
                        if (row[7]) cardB_distributor_id = atoi(row[7]); else cardB_distributor_id = -1;
                        if (row[8]) cardB_distributor_balance = atof(row[8]); else cardB_distributor_balance = 0;
                        if (row[9]) cardB_card_price = atof(row[9]); else cardB_card_price = 0;
                        if (row[10]) cardB_distributor_postpaid = atoi(row[10]); else cardB_distributor_postpaid = 0;
                        if (row[11]) cardB_distributor_credit = atof(row[11]); else cardB_distributor_credit = 0;

                        got_card = 1;
                    }
                    mysql_free_result(result);
                }
            }


        } // got pin



        if ((got_card)&&(cardB_id)) {

            sprintf(str, "Card ID: %i, balance: %f, sold: %i, valid1: %i, valid2: %i, first_use: %s, distributor_id: %i, distributor_balance: %f, distributor_credit: %f, distributor_postpaid: %i, card_price: %f", cardB_id, card_balance, cardB_sold, valid1, valid2, cardB_first_use, cardB_distributor_id, cardB_distributor_balance, cardB_distributor_credit, cardB_distributor_postpaid, cardB_card_price);
            AGITool_verbose(&agi, &res, str, 0);

            /* cardB has active calls, can't use for topup */
            if (cardB_calls) {

                AGITool_verbose(&agi, &res, "Card has active calls, cannot use for Top-Up", 0);
                AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_not_found");
                got_card = 0;

            }


            /* user tries to topup his card with his card... nasty... */
            if (cardA_id == cardB_id) {

                AGITool_verbose(&agi, &res, "Card is the same as the primary Card. Cannot use same card for Top-up itself!", 0);
                AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_not_found");
                got_card = 0;

            }


            // check for valid periods
            if ((!valid1)||(!valid2)) {

                AGITool_verbose(&agi, &res, "Card not valid, cannot use for Top-Up", 0);
                AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_expired");
                got_card = 0;

            }


            // check for sold
            if (!cardB_sold && (pin_touch_functionality == 0 || cardB_distributor_id == -1)) {

                AGITool_verbose(&agi, &res, "Card not sold, cannot use for Top-Up", 0);
                AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_is_not_sold_yet");
                got_card = 0;

            }

            // check balance
            if (card_balance <= 0) {

                AGITool_verbose(&agi, &res, "Card empty, cannot use for Top-Up", 0);
                AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_is_empty");
                got_card = 0;

            }

            if (pin_touch_functionality && !strlen(cardB_first_use) && cardB_distributor_id > 0) {

                // check if distributor can be charged for this card
                if (cardB_distributor_postpaid == 0) cardB_distributor_credit = 0;

                if (((cardB_distributor_credit + (cardB_distributor_balance - cardB_card_price)) >= 0) || (cardB_distributor_credit == -1 && cardB_distributor_postpaid == 1)) {
                    charge_distributor = 1;
                } else {
                    AGITool_verbose(&agi, &res, "Low balance for distributor. Card is not active!", 0);
                    AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_is_not_sold_yet");
                    got_card = 0;
                }
            }


        } else {

            AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/cc_card_not_found");
            got_card = 0;
        }



        retries += 1;
    } while ((!got_card)&&(retries < 3));





    if (got_card) {



        // ================= update card's A balance ==============

        sprintf(sqlcmd, "UPDATE cards SET balance = balance + %f WHERE cards.id = %i;", card_balance, cardA_id);
        mysql_query(&mysql,sqlcmd);




        // ================= mark card B as used ==============

        if (pin_touch_functionality && charge_distributor) {

            sprintf(str, "Distributor's balance will be deducted by: %f. Distributors's current balance is: %f", cardB_card_price, (cardB_distributor_balance - cardB_card_price));
            AGITool_verbose(&agi, &res, str, 0);

            sprintf(sqlcmd, "UPDATE users SET balance = balance - %f WHERE id = '%d'", cardB_card_price, cardB_distributor_id);
            if (mysql_query(&mysql, sqlcmd)) {
                sprintf(str, "MySQL error: %s", mysql_error(&mysql));
                AGITool_verbose(&agi, &res, str, 0);
            }

            sprintf(sqlcmd, "INSERT INTO actions(action, target_type, data, target_id, date, data2) VALUES('card_sold_on_pin_enter', 'Card', %d, '%d', NOW(), '%f')", cardB_distributor_id, cardB_id, cardB_card_price);
            if (mysql_query(&mysql, sqlcmd)) {
                sprintf(str, "MySQL error: %s", mysql_error(&mysql));
                AGITool_verbose(&agi, &res, str, 0);
            }

            sprintf(sqlcmd, "UPDATE cards SET balance = '0', first_use = NOW(), sold = 1 WHERE id = '%i'", cardB_id);
            if (mysql_query(&mysql, sqlcmd)) {
                sprintf(str, "MySQL error: %s", mysql_error(&mysql));
                AGITool_verbose(&agi, &res, str, 0);
            }

        } else {

            sprintf(sqlcmd, "UPDATE cards SET balance = '0', first_use = NOW() WHERE id = %i;", cardB_id);
            mysql_query(&mysql,sqlcmd);

        }


        // =============== create action to log this action =======

        sprintf(sqlcmd, "INSERT INTO actions (user_id, date, action, data, data2, target_type, target_id) VALUES ('%i', NOW(), 'card_topup', '%i', '%f', 'card', '%i');", owner_id, cardB_id, card_balance, cardA_id);
        mysql_query(&mysql,sqlcmd);

        //AGITool_verbose(&agi, &res, sqlcmd, 0);




        // ================ Tell balance ================


        mor_get_taxes(cardA_id);

        double balance = mor_count_taxes(card_balance) * exchange_rate / 100 * ghost_balance_perc;

        sprintf(str, "Balance in default currency: %f, balance with taxes and ghost_balance_perc applied in %s: %f", card_balance, currency, balance);
        AGITool_verbose(&agi, &res, str, 0);


        if (tell_balance) {

            div_t resultm;
            char curr_many[100], curr_one[100], curr_cents[100];

            resultm.quot = balance;
            resultm.rem = rint((balance - resultm.quot)*100);

            //formating sound files based on currency
            sprintf(curr_many, "mor/ivr_voices/%s_many", currency);
            sprintf(curr_one, "mor/ivr_voices/%s_one", currency);
            sprintf(curr_cents, "mor/ivr_voices/%s_cents", currency);


            AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/your_balance_was_increased_by");

            if (resultm.quot > 0) {
                AGITool_say_number(&agi, &res, resultm.quot, "");
            }


            if ( resultm.quot == 1 ) {
                AGITool_exec(&agi, &res, "PLAYBACK", curr_one);
            } else if (resultm.quot > 1) {
                AGITool_exec(&agi, &res, "PLAYBACK", curr_many);
            }

            if (resultm.quot > 0 && resultm.rem > 0) {
                AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/and");
            }

            if ( resultm.rem > 0) {
                AGITool_say_number(&agi, &res, resultm.rem, "");
                AGITool_exec(&agi, &res, "PLAYBACK", curr_cents);

            }


        }

        AGITool_exec(&agi, &res, "PLAYBACK", "mor/mor_thank_you");



    }


    AGITool_verbose(&agi, &res, "MOR Card-Topup AGI script stopped.", 0);
    AGITool_verbose(&agi, &res, "", 0);

    AGITool_Destroy(&agi);
    mysql_close(&mysql);

    return 0;
}








void mor_get_taxes(int card_id) {


    char sqlcmd[4096] = "";
    char buff[4096] = "";


    sprintf(sqlcmd, "SELECT taxes.id, compound_tax, tax2_enabled, tax3_enabled, tax4_enabled, tax1_value, tax2_value, tax3_value, tax4_value FROM taxes JOIN cardgroups ON (taxes.id = cardgroups.tax_id) JOIN cards ON (cards.cardgroup_id = cardgroups.id) WHERE cards.id = '%i';", card_id);



    //sprintf(buff, "SQL: %s\n", sqlcmd);
    //AGITool_verbose(&agi, &res, buff, 0);

    if (mysql_query(&mysql,sqlcmd)) {
        // error
        //res = -1;
    } else {
        // query succeeded, process any data returned by it
        result = mysql_store_result(&mysql);
        if (result) {
            // there are rows
            //i = 0;
            while ((row = mysql_fetch_row(result))) {

                //row[0] id
                if (row[1]) tax_compound = atoi(row[1]);
                if (row[2]) tax2_enabled = atoi(row[2]);
                if (row[3]) tax3_enabled = atoi(row[3]);
                if (row[4]) tax4_enabled = atoi(row[4]);
                if (row[5]) tax1_value = atof(row[5]);
                if (row[6]) tax2_value = atof(row[6]);
                if (row[7]) tax3_value = atof(row[7]);
                if (row[8]) tax4_value = atof(row[8]);


            }
            mysql_free_result(result);
        }
    }


    sprintf(buff, "Compound tax: %i, Enabled? tax2: %i, tax3: %i, tax4: %i, Values: tax1: %f, tax2: %f, tax3: %f, tax4: %f\n", tax_compound, tax2_enabled, tax3_enabled, tax4_enabled, tax1_value, tax2_value, tax3_value, tax4_value);
    AGITool_verbose(&agi, &res, buff, 0);

}





/* returns amount with taxes  */

float mor_count_taxes(float amount) {


    float new_amount = amount;

    /* tax1 calculation */
    new_amount += amount / 100 * tax1_value;

    /* tax2 calculation */
    if (tax2_value)
        if (tax_compound) {
            new_amount += new_amount / 100 * tax2_value;
        } else {
            new_amount += amount / 100 * tax2_value;
        }

    /* tax3 calculation */
    if (tax3_value)
        if (tax_compound) {
            new_amount += new_amount / 100 * tax3_value;
        } else {
            new_amount += amount / 100 * tax3_value;
        }

    /* tax4 calculation */

    if (tax4_value)
        if (tax_compound) {
            new_amount += new_amount / 100 * tax4_value;
        } else {
            new_amount += amount / 100 * tax4_value;
        }

    return new_amount;

}


/* returns amount without taxes  */
float mor_deduct_taxes(float amount_with_taxes) {


    float new_amount = amount_with_taxes;


    if (tax_compound) {

        if ((tax1_value != -100) && (tax2_value != -100) && (tax3_value != -100) && (tax4_value != -100)) {

            new_amount = (((amount_with_taxes / (100.00 + tax4_value) * 100.00) / (100.00 + tax3_value) * 100.00) / (100.00 + tax2_value) * 100.00) / (100.00 + tax1_value) * 100.00;

        } else {
            new_amount = amount_with_taxes;
        }


    } else {

        float all_taxes = 0;
        all_taxes = tax1_value + tax2_value + tax3_value + tax4_value;

        if (all_taxes) {
            new_amount = amount_with_taxes / (100.00 + all_taxes) * 100.00;
        } else {
            new_amount = amount_with_taxes;
        }

    }

    return new_amount;

}
