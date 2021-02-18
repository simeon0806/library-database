USE library;


CREATE VIEW v_books_with_big_raiting AS
SELECT book_name,production_year,AVG(book_rated) AS RATING FROM books as b
JOIN rating as r ON r.book_id = b.id
GROUP BY b.book_name
HAVING RATING > '4.4'
ORDER BY RATING DESC;

SELECT * FROM v_books_with_big_raiting;


DELIMITER $$
CREATE PROCEDURE udp_books_gotten_by_reader_name(`name` VARCHAR(10))
BEGIN
	SELECT CONCAT(r.first_name,' ',r.last_name) AS `Full Name`,
		b.book_name AS `Book Name`,
        b.size, rb.read_pages, t.type_name,
        CONCAT(a.first_name,' ',a.last_name) AS `author full name`
FROM books as b
    JOIN reader_book as rb 
    ON b.id = rb.book_id
    JOIN reader as r
    ON r.id = rb.reader_id
    JOIN `types` as t
    ON b.type_id = t.id
    JOIN authors as a
    ON b.author_id = a.id
    WHERE r.first_name = `name`;
END $$

CALL udp_books_gotten_by_reader_name('Ivan');

DELIMITER $$

CREATE FUNCTION function_name(ty_name VARCHAR(10) )
RETURNS INT
DETERMINISTIC
BEGIN

DECLARE sum_pages INT;

SET sum_pages := (  SELECT SUM(size) FROM books AS b
					JOIN `types` AS t 
					ON b.type_id=t.id
					WHERE t.type_name =ty_name
					GROUP BY t.type_name);
                    
RETURN sum_pages;

END $$

SELECT function_name('Thriller');

#FULL JOIN
SELECT * FROM books as b
LEFT JOIN authors as a ON b.author_id = a.id

UNION

SELECT * FROM books as b
RIGHT JOIN authors as a ON b.author_id = a.id;


DELIMITER $$
CREATE PROCEDURE udp_update_rating_for_better(rating ENUM('1','2','3','4','5'),id INT)
BEGIN

START TRANSACTION;

UPDATE rating 
SET book_rated=rating
WHERE reader_id=ID;
IF rating IN(4,5) THEN
COMMIT;
ELSE
ROLLBACK;
END IF;
END $$

CALL udp_update_rating_for_better(5,1);
CALL udp_update_rating_for_better(2,1);


DELIMITER $$
CREATE PROCEDURE cursor_loop_books()
BEGIN

DECLARE flag int;
DECLARE temp_book_name varchar(100);
DECLARE temp_year varchar(10);

DECLARE book_cursor CURSOR FOR
SELECT book_name, production_year
FROM books
WHERE size > 150;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag = 1;
SET flag = 0;

OPEN book_cursor;
book_loop: while( flag = 0)
DO
FETCH book_cursor INTO temp_book_name,temp_year;
       IF(flag = 1) THEN LEAVE book_loop;
       END IF;	
       
SELECT temp_book_name,temp_year;
end while;

CLOSE book_cursor;
SET flag = 0;
END $$

CALL cursor_loop_books();
