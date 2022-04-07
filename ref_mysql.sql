DELIMITER //
DROP PROCEDURE IF EXISTS auto_log_trigger//
CREATE PROCEDURE auto_log_trigger(tblname CHAR(30), sufftxt CHAR(10), filename CHAR(255) )
BEGIN
    SELECT DATABASE() INTO @dbname;
    SET @srctbl = CONCAT(@dbname, ".", tblname);
    SET @destdb = CONCAT(@dbname, "_", sufftxt);
    SET @desttbl = CONCAT(@destdb, ".", tblname, "_", sufftxt);

	SELECT COUNT(*) FROM information_schema.tables WHERE table_name = tblname AND table_schema = @dbname INTO @existance;
IF (@existance >= 1) then

    SET @str1 = CONCAT( "CREATE DATABASE IF NOT EXISTS ", @destdb);
    PREPARE stmt1 FROM @str1;
    EXECUTE stmt1;
    DEALLOCATE PREPARE stmt1;

    SET @str2 = "SET FOREIGN_KEY_CHECKS=0";
    PREPARE stmt2 FROM @str2;
    EXECUTE stmt2;
    DEALLOCATE PREPARE stmt2;

    SELECT COUNT(*) FROM information_schema.tables WHERE table_name = tblname AND table_schema = @destdb INTO @tblcount;
    IF (@tblcount = 0) THEN 
        SET @str3 = CONCAT("CREATE TABLE ", @desttbl," select * from ",@srctbl," where 1=2");
        PREPARE stmt3 FROM @str3;
        EXECUTE stmt3;
        DEALLOCATE PREPARE stmt3;
	
    END IF;

    
     SET @str6 = CONCAT("ALTER TABLE ", @desttbl, "
         ADD COLUMN action_taken VARCHAR(255),
         ADD COLUMN valid_from timestamp,
         ADD COLUMN valid_to timestamp,
         ADD COLUMN is_active varchar(255)
         ");
        PREPARE stmt6 FROM @str6;
        EXECUTE stmt6;
        DEALLOCATE PREPARE stmt6;

	SELECT CONCAT( "\n
    DELIMITER $$
		DROP TRIGGER IF EXISTS ", tblname, "_history_AU$$
		CREATE TRIGGER ", tblname, "_history_AU
		AFTER UPDATE ON ", tblname, "
		FOR EACH ROW
		BEGIN
			INSERT INTO ", @desttbl,
            "
			VALUES(", 
            (SELECT GROUP_CONCAT('old.', column_name) FROM information_schema.columns WHERE table_schema = @dbname AND table_name = tblname),",","'update'",",","null",
			",","now()",",","'N'",");
             
			update ", @desttbl,"
			set ",'is_active'," = 'N'
			where ",'id',"= old.",'id',";
			
			INSERT INTO ", @desttbl,
            "
			VALUES(",
            (SELECT GROUP_CONCAT('NEW.', column_name) FROM information_schema.columns WHERE table_schema = @dbname AND table_name = tblname),",","'update'",",","now()",
			",","null",",","'Y'",");
		END$$
	DELIMITER ;"
	) AS qstr FROM DUAL INTO @triggertxt;

	SELECT CONCAT( "\n 
    DELIMITER $$
		DROP TRIGGER IF EXISTS ", tblname, "_history_AI$$
		CREATE TRIGGER ", tblname, "_history_AI
		AFTER INSERT ON ", tblname, "
		FOR EACH ROW
		BEGIN
			INSERT INTO ", @desttbl,
            "
			VALUES(", 
            (SELECT GROUP_CONCAT('NEW.', column_name) FROM information_schema.columns WHERE table_schema = @dbname AND table_name = tblname),",","'insert'",",","now()",
			",","null",",","'Y'",");
	    END$$
	DELIMITER ;"
	 ) AS qstr2 FROM DUAL INTO @triggertxt2;

	SELECT CONCAT( "\n 
    DELIMITER $$
		DROP TRIGGER IF EXISTS ", tblname, "_history_AD$$
		CREATE TRIGGER ", tblname, "_history_AD
		AFTER DELETE ON ", tblname, "
		FOR EACH ROW
	    BEGIN
            update ", @desttbl,"
			set ",'is_active'," = 'N'
			where ",'id',"= old.",'id',";
            
			INSERT INTO ", @desttbl,
            "
			VALUES(", 
            (SELECT GROUP_CONCAT('OLD.', column_name) FROM information_schema.columns WHERE table_schema = @dbname AND table_name = tblname),",","'delete'",",","null",
			",","now()",",","'N'",");
            
	    END$$
	DELIMITER ;"
	 ) AS qstr3 FROM DUAL INTO @triggertxt3;

	SET @savestr = CONCAT('SELECT ', '"', @triggertxt, '"','\r\n','"', @triggertxt2, '"','\r\n','"', @triggertxt3, '"'," INTO DUMPFILE ", '"', filename, '"');
	PREPARE stmt5 FROM @savestr;
	EXECUTE stmt5;
	DEALLOCATE PREPARE stmt5;

else
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'table doesnot exist in current DB';
END iF;  
    
END//
DELIMITER ;


CALL auto_log_trigger('hello', 'history', 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/file75.sql');

SHOW VARIABLES LIKE "secure_file_priv"; 

drop table kshitijdb_history.employee_history;
select* from hello;
select * from kshitijdb_history.hello_history;

insert into hello(firstname,lastname)
values("shyam","charan"),("ramesh","aryal"); 

drop table  employee;
select * from employee;
update employee set lastname="charan" where firstname="shyam";
delete from employee where firstname="ramesh";    


