# increases limit (from 2147483647 to 18446744073709551615) for calls table, common problem for large systems exmample: #18116 
# (Query took 7008.6171 sec/~2h) on DB with 32mln calls
ALTER TABLE calls MODIFY id SERIAL;

#helps a lot for recording/adnumber selection issues
CREATE INDEX uniqueidindex ON calls (uniqueid(6)); 

# delete old unused columns
ALTER TABLE calls DROP COLUMN `dcontext`;
ALTER TABLE calls DROP COLUMN `dstchannel`;
ALTER TABLE calls DROP COLUMN `lastapp`;
ALTER TABLE calls DROP COLUMN `lastdata`;
ALTER TABLE calls DROP COLUMN `amaflags`;
ALTER TABLE calls DROP COLUMN `userfield` ;

# drop unused old indexes
DROP INDEX card_id_calldate ON calls;
DROP INDEX card_id_user_id_calldate ON calls;
#DROP INDEX card_id_2 ON calls;

# make some order with calldate column
DROP INDEX calldate ON calls;
ALTER TABLE `calls` CHANGE `calldate` `calldate` TIMESTAMP NULL;
CREATE INDEX calldateindex ON calls (calldate);

# calls.date column
ALTER TABLE `calls` ADD COLUMN `date` DATE NULL AFTER `calldate` ;
# trigger to update date when calldate is entered
CREATE TRIGGER `insert_date` BEFORE INSERT ON `calls` FOR EACH ROW SET NEW.date = LEFT(NEW.calldate, 10);
# update date column for old records
UPDATE calls SET date = LEFT(calldate, 10);
CREATE INDEX dateindex ON calls (date);

# change VARCHAR to ENUM
ALTER TABLE `calls` CHANGE `disposition` `disposition` ENUM('FAILED', 'NO ANSWER', 'BUSY', 'ANSWERED');
ALTER TABLE `calls` CHANGE `callertype` `callertype` ENUM('Local', 'Outside');

# change FLOAT to DECIMAL
# RoR3 needs this because cannot work properly with float
ALTER TABLE calls MODIFY did_price DECIMAL(30,15) DEFAULT 0;
ALTER TABLE calls MODIFY provider_rate DECIMAL(30,15) DEFAULT 0;
ALTER TABLE calls MODIFY provider_price DECIMAL(30,15) DEFAULT 0;
ALTER TABLE calls MODIFY user_rate DECIMAL(30,15) DEFAULT 0;
ALTER TABLE calls MODIFY user_price DECIMAL(30,15) DEFAULT 0;
ALTER TABLE calls MODIFY reseller_rate DECIMAL(30,15) DEFAULT 0;
ALTER TABLE calls MODIFY reseller_price DECIMAL(30,15) DEFAULT 0;
ALTER TABLE calls MODIFY partner_rate DECIMAL(30,15) DEFAULT 0;
ALTER TABLE calls MODIFY partner_price DECIMAL(30,15) DEFAULT 0;
ALTER TABLE calls MODIFY did_inc_price DECIMAL(30,15) DEFAULT 0;
ALTER TABLE calls MODIFY did_prov_price DECIMAL(30,15) DEFAULT 0;
ALTER TABLE calls MODIFY real_duration DECIMAL(30,15) DEFAULT 0;
ALTER TABLE calls MODIFY real_billsec DECIMAL(30,15) DEFAULT 0;
