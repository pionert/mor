# trigger to fix devices.username rename to devices.defaultuser
DROP TRIGGER IF EXISTS validate_device_update;
DROP TRIGGER IF EXISTS defuser;
delimiter |
CREATE TRIGGER `defuser` BEFORE UPDATE ON `devices` 
FOR EACH ROW 
BEGIN 
SET NEW.callgroup = IF(NEW.callgroup < 0 OR NEW.callgroup > 63, OLD.callgroup, NEW.callgroup);
IF LENGTH(NEW.username) THEN
SET NEW.defaultuser = NEW.username;
END IF; 
END;
|
delimiter ;