DROP PROCEDURE available_book_magazine;

Delimiter |
CREATE PROCEDURE available_book_magazine(IN book_magazine_id INT)
BEGIN

DECLARE num_book_magazine INT;
DECLARE currID INT;
DECLARE currDate DATE;
DECLARE finished INT;

DECLARE availables CURSOR FOR
SELECT library_content_id, DATE(day_of_getting) FROM curent_reading 
WHERE library_content_id = book_magazine_id;

DECLARE CONTINUE HANDLER FOR NOT FOUND  SET finished = 1;
SET finished := 0;

CREATE TEMPORARY TABLE available(
	id INT,
    `date` DATE,
    return_date DATE
)ENGINE = MEMORY;

SELECT num INTO num_book_magazine
FROM library_content
WHERE id = book_magazine_id;

IF num_book_magazine > 0 THEN
SELECT 'Книгата е налична' as "Статус";
ELSE
OPEN availables;
loop_a: WHILE(finished = 0)
DO
FETCH availables INTO currID , currDate;
IF finished = 1 THEN
LEAVE loop_a;
END IF;

INSERT INTO available
VALUES(currID , currDate, TIMESTAMPADD(MONTH,1,currDate));
END WHILE;

SELECT * FROM available
ORDER BY return_date DESC;
CLOSE availables;
END IF;

DROP TABLE available;

END
|
Delimiter ;

CALL available_book_magazine(2);
CALL available_book_magazine(1);