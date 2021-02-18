Delimiter |
CREATE PROCEDURE insert_into_curent_reading(IN r_id INT, IN lc_id INT )
BEGIN

	INSERT INTO curent_reading (reader_id, library_content_id , day_of_getting)
    VALUES (r_id,lc_id , NOW());

END
|
Delimiter ;

CALL insert_into_curent_reading (1,8);
CALL insert_into_curent_reading (2,2);
CALL insert_into_curent_reading (3,4);
CALL insert_into_curent_reading (4,5);
CALL insert_into_curent_reading (5,1);

Delimiter |
CREATE PROCEDURE update_read_pages(IN r_id INT, IN lc_id INT, IN read_pg INT)
BEGIN

	IF read_pg > 0 AND read_pg <= (
			SELECT size FROM library_content as lc
            WHERE lc.id = lc_id
    ) THEN
	UPDATE curent_reading SET read_pages = read_pg
    WHERE reader_id = r_id AND library_content_id = lc_id;
    END IF;

END
|
Delimiter ;

CALL update_read_pages(1,8,100);
CALL update_read_pages (2,2,150);
CALL update_read_pages (3,4,30);
CALL update_read_pages (4,5,70);
CALL update_read_pages (5,1,257);

Delimiter |
CREATE PROCEDURE give_raiting(in r_id INT, in lc_id INT ,in raiting ENUM('1','2','3','4','5'))
BEGIN

	IF TRUE = (		SELECT full_read FROM `history`
				WHERE reader_id = r_id AND library_content_id = lc_id
    ) THEN
	UPDATE `history`SET rated = raiting
    WHERE reader_id = r_id AND library_content_id = lc_id;
    END IF;

END
|
Delimiter ;

CALL give_raiting(5,1,5);
CALL give_raiting(4,5,5);