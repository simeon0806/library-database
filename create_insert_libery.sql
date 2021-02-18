DROP DATABASE IF EXISTS library; 
CREATE DATABASE library;
USE library;

CREATE TABLE authors(
	id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL
);

CREATE TABLE `types`(
	id INT PRIMARY KEY AUTO_INCREMENT,
    type_name VARCHAR(20) NOT NULL
);

CREATE TABLE library_content(
	id INT PRIMARY KEY AUTO_INCREMENT,
    `name` VARCHAR(50) unique,
    size INT,
    production_year YEAR,
    type_id INT,
    num INT,
    book_magazine ENUM('book','magazine'),
    
    CONSTRAINT fk_books_autors
    FOREIGN KEY (type_id) REFERENCES `types`(id)
);

CREATE TABLE authors_library_content(
	library_content_id INT,
    authors_id INT,
    
    CONSTRAINT PRIMARY KEY(library_content_id,authors_id),
    
    CONSTRAINT FOREIGN KEY (library_content_id) REFERENCES library_content(id),
    CONSTRAINT FOREIGN KEY (authors_id) REFERENCES authors(id)

);

CREATE TABLE reader(
	id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    phone_number VARCHAR(10) UNIQUE,
    read_num INT
);

CREATE TABLE employee(
	id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    phone_number VARCHAR(10) UNIQUE
);

CREATE TABLE salary(
	id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT UNIQUE,
    salary DECIMAL NOT NULL,
    
    CONSTRAINT FOREIGN KEY (employee_id) REFERENCES employee(id)
);

CREATE TABLE current_reading(
	reader_id INT NOT NULL,
    library_content_id INT NOT NULL,
    employee_id INT,
    read_pages INT default 0,
    day_of_getting DATETIME,
    
    CONSTRAINT pk_reader_book
    PRIMARY KEY (reader_id,library_content_id),
    
    CONSTRAINT fk_current_reading_reader
    FOREIGN KEY (reader_id) REFERENCES `reader`(id),
    CONSTRAINT fk_current_reading_library_content
    FOREIGN KEY (library_content_id) REFERENCES library_content(id),
    CONSTRAINT FOREIGN KEY (employee_id) REFERENCES employee(id),
    
    UNIQUE(reader_id,library_content_id)
);


CREATE TABLE `history`(
    reader_id INT NOT NULL,
    library_content_id INT NOT NULL,
    rated ENUM('1','2','3','4','5') default NULL,
    read_pages INT default 0,
    full_read BOOLEAN default false,
    
    CONSTRAINT pk_rating
    PRIMARY KEY (reader_id,library_content_id),
    
    CONSTRAINT fk_history_reader
    FOREIGN KEY (reader_id) REFERENCES `reader`(id),
    CONSTRAINT fk_history_book
    FOREIGN KEY (library_content_id) REFERENCES library_content(id)
);


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


INSERT INTO authors(first_name, last_name)
VALUES  ('Jo','Brown'),
		('Will','Duffy'),
		('Kevin','Glimp'),
		('Bob','Brown'),
		('Piterson','Selikoff'),
		('Steven','Munson');
        
INSERT INTO reader(first_name, last_name , phone_number)
VALUES  ('Simeon','Simeonov' , '0895249702'),
		('Ivan','Gorgiev','0895249982'),
		('Marija','Ivanova','0895249123'),
		('Gorgi','Stanisov','0895249583'),
		('Bojana','Angelova','0895249124'),
		('Mario','Petrov','0895342702'),
		('Anastasia','Postolova','0893249501'),
		('Dimityr','Gacov','0899269231'),
		('Kiril','Danilov','0895327623');
        
INSERT INTO `types`(type_name)
VALUES  ('Action and adventure'),
		('Drama'),
		('Crime'),
		('Science'),
		('Autobiography'),
		('Thriller'),
		('Travel');
        
INSERT INTO library_content(`name`, size, production_year,type_id,num, book_magazine)
VALUES  ('In Search of Lost Time', 257, 1970, 2, 10, 'book' ),
		('Ulysses', 302, 1991, 1, 2,'magazine'),
		('Don Quixote', 190, 1903, 2, 15,'magazine'),
		('The Great Gatsby', 600, 2002, 6, 4, 'book'),
		('Moby Dick', 220, 2014, 4, 7,'book'),
		('War and Peace', 210, 1968, 3, 12, 'book'),
		('Hamlet ', 120, 1950, 7, 9, 'magazine'),
		('The Brothers Karamazov', 140, 2001, 6, 5, 'book'),
		('Crime and Punishment ', 195, 2018, 3, 3, 'book'),
		('The Adventures of Huckleberry Finn', 315, 1999, 6, 7, 'magazine');
        
INSERT INTO authors_library_content (library_content_id , authors_id)
VALUES  (1 , 4),
		(2 , 3),
		(3 , 2),
		(3 , 6),
		(4 , 6),
		(5 , 2),
		(6 , 3),
		(6 , 1),
		(7 , 4),
		(8 , 4),
		(8 , 2),
		(9 , 1),
		(10 ,6);
        
INSERT INTO employee(first_name, last_name , phone_number)
VALUES  ('Cvetelin','Stoqnov' , '0899823421'),
		('Ivaylo','Rusunov','0892975394'),
		('Monika','Bozinova','0891479537');
        
INSERT INTO salary(employee_id ,salary)
VALUES  (1,2000),
		(2,1800),
		(3,2100);