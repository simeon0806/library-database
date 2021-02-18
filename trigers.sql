delimiter $$
CREATE TRIGGER update_history BEFORE UPDATE ON current_reading
FOR EACH ROW 
BEGIN
DECLARE temp_size_pages INT;
DECLARE temp_full_read BOOLEAN;

SELECT size
INTO temp_size_pages
FROM library_content as lc
WHERE lc.id = NEW.library_content_id;
/* Ако прочитането до тази страница е валидно промени го в табелата */
IF NEW.read_pages BETWEEN OLD.read_pages AND temp_size_pages THEN 
UPDATE `history` as h SET h.read_pages = NEW.read_pages
WHERE h.library_content_id=NEW.library_content_id and h.reader_id=NEW.reader_id;
END IF;

/* Ако е прочетана изцяло изданието отбелязи, ако не е въведи че не е */
IF NEW.read_pages = temp_size_pages THEN
SET temp_full_read = true;
ELSE
SET temp_full_read = false;
END IF;

/* Въведи го във history */
UPDATE `history` as h SET h.full_read = temp_full_read
WHERE h.library_content_id=NEW.library_content_id and h.reader_id=NEW.reader_id;

/* Добави, че читателят е прочел още една книга */
IF temp_full_read = true THEN
UPDATE reader as r SET r.read_num = IFNULL(r.read_num,0) + 1
WHERE r.id = NEW.reader_id;
END IF;

END;
$$
Delimiter ;

delimiter %%
CREATE TRIGGER insert_into_history BEFORE INSERT ON current_reading
FOR EACH ROW 
BEGIN
DECLARE temp_size INT;
DECLARE temp_full_read BOOLEAN;

SELECT size 
INTO temp_size
FROM library_content as lc
WHERE lc.id = NEW.library_content_id;

/* При вземане на книга(магазин) да се намали броя на налични от тази книга(магазин) */
UPDATE library_content AS lc 
SET lc.num = lc.num - 1 
WHERE NEW.library_content_id = lc.id;

/* Ако прочитаните страници не са валидни въведи че са 0  */
IF NEW.read_pages < 0 OR NEW.read_pages > temp_size THEN
SET NEW.read_pages = 0;
END IF;

/* Въведи ги даните във history */
INSERT INTO `history`(library_content_id,reader_id,read_pages)
VALUES (NEW.library_content_id, NEW.reader_id, NEW.read_pages);

/* Проверка дали е прочетана книгата изцяло */
IF NEW.read_pages = temp_size THEN
SET temp_full_read = true;
ELSE
SET temp_full_read = false;
END IF;

UPDATE `history` as h SET h.full_read = temp_full_read
WHERE h.library_content_id=NEW.library_content_id AND h.reader_id=NEW.reader_id;

END;
%%
Delimiter ;

Delimiter |
CREATE TRIGGER delete_on_current_reading AFTER DELETE ON current_reading
FOR EACH ROW
BEGIN

UPDATE library_content AS lc
SET lc.num = lc.num + 1
WHERE OLD.library_content_id = lc.id; 

END;
|
Delimiter ;