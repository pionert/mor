/*
*
*	MOR UseVoucher AGI script
*	Copyright Mindaugas Kezys / Kolmisoft 2008-2012
*
* 	v0.1.8
*
*	2012.11.22 v0.1.8 end script with error if no DP found
*	2012.02.16 v0.1.7 do not change language if not new language set
*	2011.08.01 v0.1.6 bigfix to apply exchange rate
*	2011.07.12 v0.1.5 block card with same number if necessary
*	2011.06.15 v0.1.4 bugfix to sounds
* 	2011.03.17 v0.1.3 bugfix to properly support taxes
* 	2010.04.16 v0.1.2 bugfix to reseller support
* 	2010.03.24 v0.1.1 reseller support
*
*	This AGI asks for voucher number and fills user's balance
*/


#include <stdio.h>
#include <stdarg.h>
#include <mysql.h>
#include <mysql/errmsg.h>
#include <time.h>
#include <sys/stat.h>
#include <math.h>


#include "mor_agi_functions.c"


	void mor_get_taxes(char voucher_number[30]); 
	float mor_count_taxes(float amount); 
	float mor_deduct_taxes(float amount_with_taxes); 
	void check_duplicate_card(char voucher_number[30]); 


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
	char buff[100];
	char str[100];
	int i;

	time_t now;


	char *variable;
	char *value;



	// variables
	
	int accountcode;
	int user_id;

	char user_first_name[50];
	char user_last_name[50];

	char extension[50];

	int owner_id = 0;

	double balance;
	double converted_balance;
	int dialplan_id;


	char currency[10];
	char language[10];
	double exchange_rate;
//	char usercard[20];


	int got_user;
	char callerid[30];
	char device_pin[30];
	
	//----------------

	char card_pin[30];
	double ghost_min_perc;
	int got_card;


	//----------------
	
	int got_voucher = 0;
	char voucher_number[30];
	int voucher_id;
	double voucher_balance_with_vat = 0;
	double voucher_vat = 0;
	char voucher_currency[10];
	double voucher_exchange_rate = 1;
	double voucher_balance = 0;		// balance in dialplans currency

	int payment_id = 0;

	int retries;


	// initial values
//	strcpy(extension, "");
//	balance = 0.0;
	converted_balance = 0.0;

	dialplan_id = 0;


	strcpy(currency, "");
	strcpy(language, "en");
	exchange_rate = 1;
//	strcpy(usercard, "");

	strcpy(user_first_name, "");
	strcpy(user_last_name, "");


	got_user = 0;
	strcpy(device_pin, "");

	strcpy(card_pin, "");
	ghost_min_perc = 100;
	got_card = 0;


	strcpy(voucher_number, "");
	strcpy(voucher_currency, "");


//	strcpy(datetime,"");

	AGITool_Init(&agi);

	AGITool_verbose(&agi, &res, "", 0);
	AGITool_verbose(&agi, &res, "MOR UseVoucher AGI script started.", 0);


	// DB connection
	read_config();

//	sprintf(str, "Host: %s, dbname: %s, user: %s, psw: %s, port: %i", dbhost, dbname, dbuser, dbpass, dbport);
//	AGITool_verbose(&agi, &res, str, 0);


	if (!mysql_connect()) {
			
    	    AGITool_verbose(&agi, &res, "ERROR! Not connected to database.", 0);
	    AGITool_Destroy(&agi);
	    return 0;
	} else {
	    AGITool_verbose(&agi, &res, "Successfully connected to database.", 0);
	}




	// Dial-Plan ID

        AGITool_get_variable2(&agi, &res, "MOR_DP_ID", buff, sizeof(buff));
	if (atoi(buff)) {
	    dialplan_id = atoi(buff);

	    sprintf(str, "Dial Plan ID: %i", dialplan_id);
	    AGITool_verbose(&agi, &res, str, 0);
	} else {

	    sprintf(str, "ERROR: Dial Plan not found, aborting");
	    AGITool_verbose(&agi, &res, str, 0);

	    goto end_script;	    

	}



	// ------- get dp details -----

	sprintf(sqlcmd, "SELECT dialplans.data3, dialplans.data4, currencies.exchange_rate FROM dialplans JOIN currencies ON (dialplans.data3 = currencies.name) WHERE dialplans.id = '%i';", dialplan_id);

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
                    if (row[0]) strcpy(currency,row[0]); 
                    if (row[1]) strcpy(language,row[1]); 
                    if (row[2]) exchange_rate = atof(row[2]); 
//                    if (row[3]) strcpy(usercard,row[3]); 
		    
            	}
        	mysql_free_result(result);
            } 
        }


	sprintf(str, "Currency: %s, language: %s, exchange rate: %f", currency, language, exchange_rate);
	AGITool_verbose(&agi, &res, str, 0);



	if (strcmp(language, "en") && (strlen(language))){
	    AGITool_set_variable(&agi, &res, "CHANNEL(language)", language);

	    sprintf(str, "Language changed to: %s",language);
	    AGITool_verbose(&agi, &res, str, 0);
	        
	} else {

	    sprintf(str, "Language not changed");
	    AGITool_verbose(&agi, &res, str, 0);
	
	}



	AGITool_answer(&agi, &res);


/*

	if (!strcmp(usercard, "user")){
*/

	    // =========== search by Accountcode ==============

    	    // Account Code

	    accountcode = atoi(AGITool_ListGetVal(agi.agi_vars, "agi_accountcode"));

	    sprintf(str, "Accountcode: %i", accountcode);
	    AGITool_verbose(&agi, &res, str, 0);


	    // ------- get user details -----

	    sprintf(sqlcmd, "SELECT users.balance, users.id, first_name, last_name, users.owner_id FROM devices JOIN users ON (devices.user_id = users.id) WHERE devices.id = '%i';", accountcode);

	    //	sprintf(str, "SQL: %s", sqlcmd);
    	    //	AGITool_verbose(&agi, &res, str, 0);
	
    	    if (mysql_query(&mysql,sqlcmd)) {    
    		// error
    	    } else {
    	    // query succeeded, process any data returned by it
    		result = mysql_store_result(&mysql);
    		if (result) {
    		    // there are rows
        	    //i = 0;
            	    while ((row = mysql_fetch_row(result))) {	
                	if (row[0]) balance = atof(row[0]); 
                	if (row[1]) user_id = atoi(row[1]); 
                	if (row[2]) strcpy(user_first_name, row[2]);
                	if (row[3]) strcpy(user_last_name, row[3]);
                	if (row[4]) owner_id = atoi(row[4]); 

            		got_user = 1;
		    }
        	    mysql_free_result(result);
        	} 
    	    }



	    // ================== search by CallerID using ANI ==========
	    if (!got_user){


    	        // CallerID
    		AGITool_get_variable2(&agi, &res, "CALLERID(num)", buff, sizeof(buff));
		if (buff) {
		    strcpy(callerid, buff);
		} else {
		    strcpy(callerid, "");		
		}


		if (strlen(callerid) > 0){

		    sprintf(str, "User not found by accountcode, will search using ANI by CallerID: %s", callerid);
		    AGITool_verbose(&agi, &res, str, 0);


		    sprintf(sqlcmd, "SELECT users.balance, users.id, first_name, last_name, users.owner_id FROM devices JOIN users ON (devices.user_id = users.id) JOIN callerids ON (callerids.device_id = devices.id) WHERE callerids.cli = '%s';", callerid);

		    //sprintf(str, "SQL: %s", sqlcmd);
    		    //AGITool_verbose(&agi, &res, str, 0);
	
    		    if (mysql_query(&mysql,sqlcmd)) {    
    			// error
    		    } else {
    			// query succeeded, process any data returned by it
    			result = mysql_store_result(&mysql);
    			if (result) {
    			    // there are rows
        		    //i = 0;
            		    while ((row = mysql_fetch_row(result))) {	
                		if (row[0]) balance = atof(row[0]); 
                		if (row[1]) user_id = atoi(row[1]); 
                		if (row[2]) strcpy(user_first_name, row[2]);
                		if (row[3]) strcpy(user_last_name, row[3]);
                		if (row[4]) owner_id = atoi(row[4]); 

            			got_user = 1;
			    }
        		    mysql_free_result(result);
        		} 
    		    }
		}    
	    }


	    // ================== search user by PIN ==========
	    if (!got_user){


		AGITool_verbose(&agi, &res, "User not found by CallerID using ANI, will ask PIN now", 0);



		retries = 0;
		do {
		    

		    // ask device pin 
		    AGITool_get_data(&agi, &res, "mor/ivr_voices/enter_pin", 10000, 30);
	
		    strcpy(device_pin, res.result);
		    sprintf(str, "PIN entered: %s", device_pin);
		    AGITool_verbose(&agi, &res, str, 0);


		    // ------- get user details -----

		    if (strlen(device_pin) > 0){

			sprintf(sqlcmd, "SELECT users.balance, users.id, first_name, last_name, users.owner_id FROM devices JOIN users ON (devices.user_id = users.id) WHERE devices.pin = '%s';", device_pin);

			//sprintf(str, "SQL: %s", sqlcmd);
    			//AGITool_verbose(&agi, &res, str, 0);
	
    			if (mysql_query(&mysql,sqlcmd)) {    
    			    // error
    			} else {
    			    // query succeeded, process any data returned by it
    			    result = mysql_store_result(&mysql);
    			    if (result) {
    			        // there are rows
            			while ((row = mysql_fetch_row(result))) {	
                		    if (row[0]) balance = atof(row[0]); 
                		    if (row[1]) user_id = atoi(row[1]); 
                		    if (row[2]) strcpy(user_first_name, row[2]);
                		    if (row[3]) strcpy(user_last_name, row[3]);
                		    if (row[4]) owner_id = atoi(row[4]);

            			    got_user = 1;
				}
        			mysql_free_result(result);
        		    } 
    			}
		
		    }
	    

		    retries += 1;
		} while ((!got_user)&&(retries < 3));
	    }
	




		    if (got_user){

			sprintf(str, "User found! ID: %i, first name: %s, last name: %s, balance: %f, owner_id: %i", user_id, user_first_name, user_last_name, balance, owner_id);
			AGITool_verbose(&agi, &res, str, 0);

		    } else {
	    
			AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/auth_failed");
		    }




// ============= ask voucher number ============

    if (got_user){
	    retries = 0;
	    do {
		    

		// ask voucher pin 
		AGITool_get_data(&agi, &res, "mor/ivr_voices/enter_voucher_number", 10000, 30);


		strcpy(voucher_number, res.result);
		sprintf(str, "Voucher number entered: %s", voucher_number);
		AGITool_verbose(&agi, &res, str, 0);

		// ------- get voucher details -----

		sprintf(sqlcmd, "SELECT vouchers.id, credit_with_vat, vat_percent, vouchers.currency, currencies.exchange_rate FROM vouchers JOIN currencies ON (vouchers.currency = currencies.name) WHERE number = '%s' AND active_till >= CURRENT_DATE() AND user_id = -1 LIMIT 1;", voucher_number);

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
                	    if (row[0]) voucher_id = atoi(row[0]); 
                	    if (row[1]) voucher_balance_with_vat = atof(row[1]); 
                	    if (row[2]) voucher_vat = atof(row[2]); 
                	    if (row[3]) strcpy(voucher_currency, row[3]); 
                	    if (row[4]) voucher_exchange_rate = atof(row[4]); 
			    
            		    got_voucher = 1;
			}
        		mysql_free_result(result);
        	    } 
    		}


		if (got_voucher){

		    // balance without vat in default currency
		    //voucher_balance = voucher_balance_with_vat / (100 + voucher_vat) * 100 / voucher_exchange_rate;


		    mor_get_taxes(voucher_number);
		    
		    voucher_balance = mor_deduct_taxes(voucher_balance_with_vat) / voucher_exchange_rate;

		    sprintf(str, "Voucher id: %i, balance with vat: %f, vat: %f%, currency: %s, exchange rate: %f, balance in default currency without vat: %f", voucher_id, voucher_balance_with_vat, voucher_vat, voucher_currency, voucher_exchange_rate, voucher_balance);
		    AGITool_verbose(&agi, &res, str, 0);

		} else {
	    
		    AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/voucher_not_found");
		}



		retries += 1;
	    } while ((!got_voucher)&&(retries < 3));




        if (got_voucher){
    



	    // ================= update users balance ==============
	
	    sprintf(sqlcmd, "UPDATE users SET users.balance = users.balance + %f WHERE users.id = %i;", voucher_balance, user_id);
	    mysql_query(&mysql,sqlcmd);


	    // ================= create payment ==============
	
	    sprintf(sqlcmd, "INSERT INTO payments (paymenttype, amount, currency, date_added, shipped_at, completed, user_id, first_name, last_name, vat_percent, owner_id, gross, tax) VALUES ('voucher', '%f', '%s', NOW(), NOW(), '1', '%i', '%s', '%s', '%f', '%i', '%f', '%f');", voucher_balance_with_vat, voucher_currency, user_id, user_first_name, user_last_name, voucher_vat, owner_id, voucher_balance, voucher_balance_with_vat - voucher_balance);
//	    AGITool_verbose(&agi, &res, sqlcmd, 0);
	    mysql_query(&mysql,sqlcmd);


	    // ================= reseller support ==============

	    if (owner_id){

		// increase resellers balance
		sprintf(sqlcmd, "UPDATE users SET users.balance = users.balance + %f WHERE users.id = %i;", voucher_balance, owner_id);
		mysql_query(&mysql,sqlcmd);

		// payment for reseller
		sprintf(sqlcmd, "INSERT INTO payments (paymenttype, amount, currency, date_added, shipped_at, completed, user_id, first_name, last_name, vat_percent, owner_id, gross, tax) VALUES ('voucher', '%f', '%s', NOW(), NOW(), '1', '%i', '%s', '%s', '%f', '0', '%f', '%f');", voucher_balance_with_vat, voucher_currency, owner_id, user_first_name, user_last_name, voucher_vat, voucher_balance, voucher_balance_with_vat - voucher_balance);
		mysql_query(&mysql,sqlcmd);
    


	    }


	    // ================= get payment id ==============

	    sprintf(sqlcmd, "SELECT payments.id FROM payments WHERE user_id = '%i' AND amount = '%f' AND owner_id = '%i' ORDER BY date_added DESC LIMIT 1;", user_id, voucher_balance_with_vat, owner_id);
	    //AGITool_verbose(&agi, &res, sqlcmd, 0);	    
    		if (mysql_query(&mysql,sqlcmd)) {    
    		} else {    // query succeeded, process any data returned by it
    		    result = mysql_store_result(&mysql);
    		    if (result) {
            		while ((row = mysql_fetch_row(result))) {	
                	    if (row[0]) payment_id = atoi(row[0]); 
			}
        		mysql_free_result(result);
        	    } 
    		}


	    // ================= mark voucher as used ==============
	
	    sprintf(sqlcmd, "UPDATE vouchers SET user_id = %i, use_date = NOW(), payment_id = '%i' WHERE id = %i;", user_id, payment_id, voucher_id);
	    mysql_query(&mysql,sqlcmd);	    
	
	
	    
	    /* check if we need to block card with same number and block it if necessary */
	    check_duplicate_card(voucher_number);
	    
    
	}

    
    } // got user
    
/*

	} else {
	    // card
	    

	    retries = 0;
	    do {
		    

		// ask card pin 
		AGITool_get_data(&agi, &res, "mor/mor_enter_pin_number", 10000, 30);
	
		strcpy(card_pin, res.result);
		sprintf(str, "PIN entered: %s", card_pin);
		AGITool_verbose(&agi, &res, str, 0);


		// ------- get card details -----

		sprintf(sqlcmd, "SELECT cards.balance, cardgroups.ghost_min_perc FROM cards JOIN cardgroups ON (cards.cardgroup_id = cardgroups.id) WHERE cards.pin = '%s';", card_pin);

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
                	    if (row[0]) balance = atof(row[0]); 
                	    if (row[1]) ghost_min_perc = atof(row[1]); 
            		    got_card = 1;
			}
        		mysql_free_result(result);
        	    } 
    		}
		
	    
		if (got_card){

		    sprintf(str, "Balance: %f, ghost min perc: %f %", balance, ghost_min_perc);
		    AGITool_verbose(&agi, &res, str, 0);

		    balance = (balance / 100 * ghost_min_perc);

		    sprintf(str, "Final balance: %f", balance);
		    AGITool_verbose(&agi, &res, str, 0);

		} else {
	    
		    AGITool_exec(&agi, &res, "PLAYBACK", "mor/morcc_auth_failed");
		}


		retries += 1;
	    } while ((!got_card)&&(retries < 3));
	    

	
	}

*/




	
	if (got_voucher) {


	    // Convert balance
//	    if (exchange_rate)
//		converted_balance = balance * exchange_rate;
//	    else
//    		converted_balance = balance;

	    converted_balance = voucher_balance_with_vat;
	    strcpy(currency, voucher_currency);
    

	    if (converted_balance < 0)
		converted_balance = converted_balance * (-1);

//	    sprintf(str, "Converted balance: %f %s", converted_balance, currency);
//	    AGITool_verbose(&agi, &res, str, 0);



	// Tell balance
	
	    div_t resultm; 
	    char curr_many[100], curr_one[100], curr_cents[100]; 


	    resultm.quot = converted_balance;
	    resultm.rem = rint((converted_balance - resultm.quot)*100);
	
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
	    } else
	        if (resultm.quot > 1) {
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


	AGITool_exec(&agi, &res, "PLAYBACK", "mor/ivr_voices/thank_you");


    end_script:

	AGITool_verbose(&agi, &res, "MOR UseVoucher AGI script stopped.", 0);
	AGITool_verbose(&agi, &res, "", 0);

	AGITool_Destroy(&agi);
	mysql_close(&mysql);  

	return 0;
}












void check_duplicate_card(char voucher_number[30]){

    char buff[4096] = "";
    char sqlcmd[2048] = "";
    int disable = 0;
    int card_id = 0;


    sprintf(buff, "Checking for duplicate card\n");
    AGITool_verbose(&agi, &res, buff, 0);


    sprintf(sqlcmd, "SELECT (SELECT value FROM `conflines` WHERE name = 'Voucher_Card_Disable' AND owner_id = 0), (SELECT id FROM cards WHERE number = '%s');", voucher_number);        

	    sprintf(buff, "SQL: %s\n", sqlcmd);
	//    AGITool_verbose(&agi, &res, buff, 0);

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

			    if (row[0]) disable = atoi(row[0]);
			    if (row[1]) card_id = atoi(row[1]);

			}
        		mysql_free_result(result);
        	    } 
    		}


	    sprintf(buff, "Disable: %i, Card ID: %i\n", disable, card_id);
	    //AGITool_verbose(&agi, &res, buff, 0);

    
    if (disable){
    
	if (card_id){
	
	    sprintf(sqlcmd, "UPDATE cards SET sold = 0 WHERE cards.id = %i;", card_id);
	    mysql_query(&mysql,sqlcmd);
	    
	    sprintf(buff, "Card (ID: %i, Number: %s) blocked\n", card_id, voucher_number);
	    AGITool_verbose(&agi, &res, buff, 0);	    
	    
	}
    
    }

}






void mor_get_taxes(char voucher_number[30]){


    char sqlcmd[2048] = "";
//    MYSQL_RES   *result;
//    MYSQL_ROW   row;
//   int res=0;
                    

    char buff[1024] = "";


    sprintf(sqlcmd, "SELECT taxes.id, compound_tax, tax2_enabled, tax3_enabled, tax4_enabled, tax1_value, tax2_value, tax3_value, tax4_value FROM taxes JOIN vouchers ON (taxes.id = vouchers.tax_id) WHERE vouchers.number = '%s';", voucher_number);        


//    if (got_user){
	/* sql for user */
//        sprintf(sqlcmd, "SELECT taxes.id, compound_tax, tax2_enabled, tax3_enabled, tax4_enabled, tax1_value, tax2_value, tax3_value, tax4_value FROM taxes JOIN users ON (taxes.id = users.tax_id) JOIN devices ON (devices.user_id = users.id) WHERE devices.id = %i;", accountcode);        
//    } else {
	/* sql for card */
//	sprintf(sqlcmd, "SELECT taxes.id, compound_tax, tax2_enabled, tax3_enabled, tax4_enabled, tax1_value, tax2_value, tax3_value, tax4_value FROM taxes JOIN cardgroups ON (taxes.id = cardgroups.tax_id) JOIN cards ON (cards.cardgroup_id = cardgroups.id) WHERE cards.id = %i;", card_id);	
//    }


	    sprintf(buff, "SQL: %s\n", sqlcmd);
	    AGITool_verbose(&agi, &res, buff, 0);

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
float mor_count_taxes(float amount){


    float new_amount = amount;

    /* tax1 calculation */
    new_amount += amount / 100 * tax1_value;
    
    /* tax2 calculation */
    if (tax2_value)
	if (tax_compound){
	    new_amount += new_amount / 100 * tax2_value;
	} else {
	    new_amount += amount / 100 * tax2_value;
	}

    /* tax3 calculation */
    if (tax3_value)
	if (tax_compound){
	    new_amount += new_amount / 100 * tax3_value;
	} else {
	    new_amount += amount / 100 * tax3_value;
	}

    /* tax4 calculation */

    if (tax4_value)
	if (tax_compound){
	    new_amount += new_amount / 100 * tax4_value;
	} else {
	    new_amount += amount / 100 * tax4_value;
	}

    return new_amount;

}


/* returns amount without taxes  */
float mor_deduct_taxes(float amount_with_taxes){


    float new_amount = amount_with_taxes;


    if (tax_compound){
    
	if ((tax1_value != -100) && (tax2_value != -100) && (tax3_value != -100) && (tax4_value != -100)){
	
	    new_amount = (((amount_with_taxes / (100.00 + tax4_value) * 100.00) / (100.00 + tax3_value) * 100.00) / (100.00 + tax2_value) * 100.00) / (100.00 + tax1_value) * 100.00;
	
	} else {
	    new_amount = amount_with_taxes;	
	}

    
    } else {

	float all_taxes = 0;
	all_taxes = tax1_value + tax2_value + tax3_value + tax4_value;
	
	if (all_taxes){    
	    new_amount = amount_with_taxes / (100.00 + all_taxes) * 100.00;
	} else {
	    new_amount = amount_with_taxes;
	}
    
    }

    return new_amount;

}
