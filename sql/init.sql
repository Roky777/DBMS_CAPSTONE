-- =====================================================================
-- LIBRARY MANAGEMENT SYSTEM  --  DBMS Capstone Project
-- File 1 of 4 : SCHEMA (DDL)  --  MySQL 8.0+
-- Demonstrates: 3NF design, PK/FK constraints, 1:M and M:N relationships,
--               CHECK / UNIQUE / NOT NULL constraints, indexes.
-- =====================================================================

DROP DATABASE IF EXISTS library_db;
CREATE DATABASE library_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE library_db;

-- ---------------------------------------------------------------------
-- 1. PUBLISHER  (1 publisher : M books)
-- ---------------------------------------------------------------------
CREATE TABLE publisher (
    publisher_id   INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(120) NOT NULL UNIQUE,
    address        VARCHAR(200),
    city           VARCHAR(60),
    country        VARCHAR(60) DEFAULT 'India',
    contact_email  VARCHAR(120),
    phone          VARCHAR(20)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. CATEGORY  (self-referencing optional parent -> recursive 1:M)
-- ---------------------------------------------------------------------
CREATE TABLE category (
    category_id    INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(80) NOT NULL UNIQUE,
    parent_id      INT NULL,
    CONSTRAINT fk_category_parent
        FOREIGN KEY (parent_id) REFERENCES category(category_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. AUTHOR
-- ---------------------------------------------------------------------
CREATE TABLE author (
    author_id      INT AUTO_INCREMENT PRIMARY KEY,
    first_name     VARCHAR(60) NOT NULL,
    last_name      VARCHAR(60) NOT NULL,
    nationality    VARCHAR(60),
    birth_year     SMALLINT,
    CONSTRAINT chk_birth_year CHECK (birth_year IS NULL OR birth_year BETWEEN 1000 AND 2025)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. BOOK  (title-level record; M:1 to publisher and category)
-- ---------------------------------------------------------------------
CREATE TABLE book (
    book_id        INT AUTO_INCREMENT PRIMARY KEY,
    isbn           CHAR(13) NOT NULL UNIQUE,
    title          VARCHAR(200) NOT NULL,
    publisher_id   INT NOT NULL,
    category_id    INT NOT NULL,
    edition        VARCHAR(20),
    publication_year SMALLINT,
    language       VARCHAR(30) DEFAULT 'English',
    price          DECIMAL(8,2) CHECK (price >= 0),
    CONSTRAINT fk_book_publisher
        FOREIGN KEY (publisher_id) REFERENCES publisher(publisher_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_book_category
        FOREIGN KEY (category_id) REFERENCES category(category_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. BOOK_AUTHOR  (junction table : M:N book <-> author)
-- ---------------------------------------------------------------------
CREATE TABLE book_author (
    book_id        INT NOT NULL,
    author_id      INT NOT NULL,
    author_role    VARCHAR(30) DEFAULT 'Author',
    PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_ba_book
        FOREIGN KEY (book_id) REFERENCES book(book_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ba_author
        FOREIGN KEY (author_id) REFERENCES author(author_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. BOOK_COPY  (each physical copy; 1 book : M copies)
-- ---------------------------------------------------------------------
CREATE TABLE book_copy (
    copy_id        INT AUTO_INCREMENT PRIMARY KEY,
    book_id        INT NOT NULL,
    barcode        VARCHAR(30) NOT NULL UNIQUE,
    shelf_location VARCHAR(30),
    status         ENUM('Available','Borrowed','Reserved','Lost','Damaged')
                   NOT NULL DEFAULT 'Available',
    acquired_date  DATE,
    CONSTRAINT fk_copy_book
        FOREIGN KEY (book_id) REFERENCES book(book_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. MEMBER
-- ---------------------------------------------------------------------
CREATE TABLE member (
    member_id      INT AUTO_INCREMENT PRIMARY KEY,
    first_name     VARCHAR(60) NOT NULL,
    last_name      VARCHAR(60) NOT NULL,
    email          VARCHAR(120) NOT NULL UNIQUE,
    phone          VARCHAR(20),
    address        VARCHAR(200),
    membership_type ENUM('Student','Faculty','Public') NOT NULL DEFAULT 'Student',
    join_date      DATE NOT NULL,
    is_active      BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. STAFF  (librarians who process loans)
-- ---------------------------------------------------------------------
CREATE TABLE staff (
    staff_id       INT AUTO_INCREMENT PRIMARY KEY,
    first_name     VARCHAR(60) NOT NULL,
    last_name      VARCHAR(60) NOT NULL,
    email          VARCHAR(120) NOT NULL UNIQUE,
    role           VARCHAR(40) DEFAULT 'Librarian',
    hire_date      DATE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. BORROWING  (borrow-return transaction; copy <-> member)
-- ---------------------------------------------------------------------
CREATE TABLE borrowing (
    borrow_id      INT AUTO_INCREMENT PRIMARY KEY,
    copy_id        INT NOT NULL,
    member_id      INT NOT NULL,
    issued_by      INT,                       -- staff
    borrow_date    DATE NOT NULL,
    due_date       DATE NOT NULL,
    return_date    DATE NULL,
    CONSTRAINT fk_borrow_copy
        FOREIGN KEY (copy_id) REFERENCES book_copy(copy_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_borrow_member
        FOREIGN KEY (member_id) REFERENCES member(member_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_borrow_staff
        FOREIGN KEY (issued_by) REFERENCES staff(staff_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_due_after_borrow CHECK (due_date >= borrow_date),
    CONSTRAINT chk_return_after_borrow CHECK (return_date IS NULL OR return_date >= borrow_date)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 10. FINE  (1:1 with an overdue/lost borrowing)
-- ---------------------------------------------------------------------
CREATE TABLE fine (
    fine_id        INT AUTO_INCREMENT PRIMARY KEY,
    borrow_id      INT NOT NULL UNIQUE,
    amount         DECIMAL(8,2) NOT NULL CHECK (amount >= 0),
    reason         VARCHAR(100),
    paid           BOOLEAN NOT NULL DEFAULT FALSE,
    paid_date      DATE NULL,
    CONSTRAINT fk_fine_borrow
        FOREIGN KEY (borrow_id) REFERENCES borrowing(borrow_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 11. RESERVATION  (member reserves a title)
-- ---------------------------------------------------------------------
CREATE TABLE reservation (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id        INT NOT NULL,
    member_id      INT NOT NULL,
    reserved_date  DATE NOT NULL,
    status         ENUM('Pending','Fulfilled','Cancelled') NOT NULL DEFAULT 'Pending',
    CONSTRAINT fk_res_book
        FOREIGN KEY (book_id) REFERENCES book(book_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_res_member
        FOREIGN KEY (member_id) REFERENCES member(member_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- INDEXES (beyond the automatic PK / UNIQUE indexes)
-- ---------------------------------------------------------------------
CREATE INDEX idx_book_title      ON book(title);
CREATE INDEX idx_book_category   ON book(category_id);
CREATE INDEX idx_copy_status     ON book_copy(status);
CREATE INDEX idx_borrow_member   ON borrowing(member_id);
CREATE INDEX idx_borrow_due      ON borrowing(due_date);
CREATE INDEX idx_member_name     ON member(last_name, first_name);

-- ---------------------------------------------------------------------
-- ALTER demonstration (required by handbook): add an audit column
-- ---------------------------------------------------------------------
ALTER TABLE member ADD COLUMN last_updated TIMESTAMP
      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
-- =====================================================================
-- LIBRARY MANAGEMENT SYSTEM  --  File 2 of 4 : SAMPLE DATA (DML INSERTs)
-- 100+ meaningful records across all tables.
-- =====================================================================
USE library_db;

-- ---------------- PUBLISHERS (10) ----------------
INSERT INTO publisher (name, address, city, country, contact_email, phone) VALUES
('Penguin Random House','11 Community Centre','New Delhi','India','contact@penguin.in','011-23456701'),
('Oxford University Press','YMCA Library Bldg','New Delhi','India','info@oup.in','011-23456702'),
('Pearson Education','15th Floor Tower','Noida','India','support@pearson.in','0120-2345670'),
('McGraw Hill','B-4 Sector 63','Noida','India','care@mheducation.in','0120-2345671'),
('HarperCollins','A-75 Sector 57','Noida','India','hello@harpercollins.in','0120-2345672'),
('Cambridge University Press','Treasury Building','Mumbai','India','india@cambridge.org','022-23456703'),
('Wiley India','4435-36 Ansari Road','New Delhi','India','csupport@wiley.com','011-23456704'),
('Bloomsbury','DDA Complex','New Delhi','India','contact@bloomsbury.in','011-23456705'),
('Springer Nature','7th Floor Vijaya Bldg','New Delhi','India','india@springer.com','011-23456706'),
('Scholastic India','A-27 Sector 16','Noida','India','help@scholastic.in','0120-2345673');

-- ---------------- CATEGORIES (12, with hierarchy) ----------------
INSERT INTO category (name, parent_id) VALUES
('Fiction', NULL),            -- 1
('Non-Fiction', NULL),        -- 2
('Science', NULL),            -- 3
('Technology', NULL),         -- 4
('Mystery', 1),               -- 5  child of Fiction
('Fantasy', 1),               -- 6  child of Fiction
('Biography', 2),             -- 7  child of Non-Fiction
('History', 2),               -- 8  child of Non-Fiction
('Physics', 3),               -- 9  child of Science
('Computer Science', 4),      -- 10 child of Technology
('Mathematics', 3),           -- 11 child of Science
('Children', NULL);           -- 12

-- ---------------- AUTHORS (20) ----------------
INSERT INTO author (first_name, last_name, nationality, birth_year) VALUES
('George','Orwell','British',1903),
('Jane','Austen','British',1775),
('Agatha','Christie','British',1890),
('J.K.','Rowling','British',1965),
('Stephen','Hawking','British',1942),
('Yuval','Harari','Israeli',1976),
('Thomas','Cormen','American',1956),
('Andrew','Tanenbaum','American',1944),
('Abraham','Silberschatz','American',1950),
('Robert','Martin','American',1952),
('Chetan','Bhagat','Indian',1974),
('Arundhati','Roy','Indian',1961),
('R.K.','Narayan','Indian',1906),
('Dan','Brown','American',1964),
('Paulo','Coelho','Brazilian',1947),
('Walter','Isaacson','American',1952),
('Ramez','Elmasri','American',1950),
('Herbert','Schildt','American',1951),
('Bjarne','Stroustrup','Danish',1950),
('Carl','Sagan','American',1934);

-- ---------------- BOOKS (25) ----------------
INSERT INTO book (isbn, title, publisher_id, category_id, edition, publication_year, language, price) VALUES
('9780141036144','1984',1,1,'1st',1949,'English',399.00),
('9780141439518','Pride and Prejudice',1,1,'Reprint',1813,'English',299.00),
('9780062073488','Murder on the Orient Express',5,5,'2nd',1934,'English',349.00),
('9780747532699','Harry Potter and the Philosopher''s Stone',8,6,'1st',1997,'English',599.00),
('9780553380163','A Brief History of Time',1,9,'Updated',1988,'English',499.00),
('9780099590088','Sapiens: A Brief History of Humankind',5,8,'1st',2011,'English',699.00),
('9780262033848','Introduction to Algorithms',4,10,'3rd',2009,'English',899.00),
('9780132126953','Computer Networks',3,10,'5th',2010,'English',749.00),
('9781118063514','Database System Concepts',7,10,'6th',2010,'English',825.00),
('9780132350884','Clean Code',3,10,'1st',2008,'English',650.00),
('9788129135728','Five Point Someone',5,1,'1st',2004,'English',199.00),
('9780006550686','The God of Small Things',5,1,'1st',1997,'English',350.00),
('9788185986173','Malgudi Days',2,1,'Reprint',1943,'English',250.00),
('9780307474278','The Da Vinci Code',1,5,'Reprint',2003,'English',450.00),
('9780061122415','The Alchemist',5,1,'25th Anniv',1988,'English',299.00),
('9781451648539','Steve Jobs',6,7,'1st',2011,'English',799.00),
('9780133970777','Fundamentals of Database Systems',3,10,'7th',2015,'English',950.00),
('9780078022159','Java: The Complete Reference',4,10,'9th',2014,'English',675.00),
('9780321563842','The C++ Programming Language',3,10,'4th',2013,'English',880.00),
('9780345539434','Cosmos',1,3,'Reprint',1980,'English',420.00),
('9780747538486','Harry Potter and the Chamber of Secrets',8,6,'1st',1998,'English',599.00),
('9780062315007','The Alchemist Illustrated',5,1,'Illustrated',1988,'English',550.00),
('9780099518471','Atonement',1,1,'Reprint',2001,'English',375.00),
('9788172234980','The White Tiger',8,1,'1st',2008,'English',325.00),
('9780062316097','Homo Deus',5,2,'1st',2015,'English',650.00);

-- ---------------- BOOK_AUTHOR (M:N, 28 links) ----------------
INSERT INTO book_author (book_id, author_id, author_role) VALUES
(1,1,'Author'),(2,2,'Author'),(3,3,'Author'),(4,4,'Author'),(5,5,'Author'),
(6,6,'Author'),(7,7,'Author'),
(8,8,'Author'),(9,9,'Author'),(10,10,'Author'),(11,11,'Author'),(12,12,'Author'),
(13,13,'Author'),(14,14,'Author'),(15,15,'Author'),(16,16,'Author'),
(17,17,'Author'),(18,18,'Author'),(19,19,'Author'),(20,20,'Author'),
(21,4,'Author'),(22,15,'Author'),(25,6,'Author'),
(9,17,'Co-Author'),       -- one book, multiple authors (M:N)
(17,9,'Co-Author'),       -- one author on multiple books (M:N)
(5,20,'Foreword'),
(20,5,'Foreword');

-- ---------------- BOOK_COPY (40 copies) ----------------
INSERT INTO book_copy (book_id, barcode, shelf_location, status, acquired_date) VALUES
(1,'BC0001','A1-01','Available','2022-01-10'),
(1,'BC0002','A1-01','Borrowed','2022-01-10'),
(2,'BC0003','A1-02','Available','2022-01-15'),
(3,'BC0004','A2-01','Borrowed','2022-02-01'),
(4,'BC0005','B1-01','Borrowed','2022-02-10'),
(4,'BC0006','B1-01','Available','2022-02-10'),
(4,'BC0007','B1-01','Reserved','2022-02-10'),
(5,'BC0008','C1-01','Available','2022-03-05'),
(6,'BC0009','C2-01','Borrowed','2022-03-12'),
(6,'BC0010','C2-01','Available','2022-03-12'),
(7,'BC0011','D1-01','Borrowed','2022-04-01'),
(7,'BC0012','D1-01','Available','2022-04-01'),
(8,'BC0013','D1-02','Available','2022-04-05'),
(9,'BC0014','D1-03','Borrowed','2022-04-10'),
(9,'BC0015','D1-03','Available','2022-04-10'),
(10,'BC0016','D2-01','Borrowed','2022-05-01'),
(11,'BC0017','A1-03','Available','2022-05-10'),
(12,'BC0018','A1-04','Available','2022-05-15'),
(13,'BC0019','A1-05','Borrowed','2022-06-01'),
(14,'BC0020','A2-02','Available','2022-06-10'),
(15,'BC0021','A1-06','Borrowed','2022-06-15'),
(15,'BC0022','A1-06','Available','2022-06-15'),
(16,'BC0023','E1-01','Available','2022-07-01'),
(17,'BC0024','D2-02','Borrowed','2022-07-10'),
(17,'BC0025','D2-02','Available','2022-07-10'),
(18,'BC0026','D2-03','Available','2022-08-01'),
(19,'BC0027','D2-04','Borrowed','2022-08-10'),
(20,'BC0028','C1-02','Available','2022-08-15'),
(21,'BC0029','B1-02','Available','2022-09-01'),
(22,'BC0030','A1-07','Lost','2022-09-10'),
(23,'BC0031','A1-08','Available','2022-09-15'),
(24,'BC0032','A1-09','Borrowed','2022-10-01'),
(25,'BC0033','C2-02','Available','2022-10-10'),
(5,'BC0034','C1-03','Borrowed','2022-10-15'),
(7,'BC0035','D1-04','Available','2023-01-05'),
(9,'BC0036','D1-06','Damaged','2023-01-10'),
(10,'BC0037','D2-05','Available','2023-02-01'),
(1,'BC0038','A1-01','Available','2023-02-10'),
(4,'BC0039','B1-01','Borrowed','2023-03-01'),
(6,'BC0040','C2-01','Available','2023-03-10');

-- ---------------- MEMBERS (20) ----------------
INSERT INTO member (first_name, last_name, email, phone, address, membership_type, join_date, is_active) VALUES
('Rahul','Sharma','rahul.sharma@email.com','9810000001','Lajpat Nagar, Delhi','Student','2022-01-05',TRUE),
('Priya','Verma','priya.verma@email.com','9810000002','Sector 15, Noida','Student','2022-01-12',TRUE),
('Amit','Patel','amit.patel@email.com','9810000003','Andheri, Mumbai','Faculty','2022-02-01',TRUE),
('Sneha','Gupta','sneha.gupta@email.com','9810000004','Salt Lake, Kolkata','Public','2022-02-15',TRUE),
('Vikram','Singh','vikram.singh@email.com','9810000005','Civil Lines, Delhi','Student','2022-03-01',TRUE),
('Anjali','Nair','anjali.nair@email.com','9810000006','Kochi, Kerala','Faculty','2022-03-10',TRUE),
('Karan','Mehta','karan.mehta@email.com','9810000007','Bandra, Mumbai','Student','2022-04-05',TRUE),
('Pooja','Reddy','pooja.reddy@email.com','9810000008','Banjara Hills, Hyderabad','Public','2022-04-20',TRUE),
('Arjun','Kumar','arjun.kumar@email.com','9810000009','Indiranagar, Bangalore','Student','2022-05-01',TRUE),
('Divya','Iyer','divya.iyer@email.com','9810000010','T Nagar, Chennai','Faculty','2022-05-15',TRUE),
('Rohan','Joshi','rohan.joshi@email.com','9810000011','Kothrud, Pune','Student','2022-06-01',TRUE),
('Meera','Pillai','meera.pillai@email.com','9810000012','Vasant Kunj, Delhi','Public','2022-06-20',TRUE),
('Sanjay','Rao','sanjay.rao@email.com','9810000013','Jubilee Hills, Hyderabad','Faculty','2022-07-01',TRUE),
('Nisha','Agarwal','nisha.agarwal@email.com','9810000014','Malviya Nagar, Jaipur','Student','2022-07-15',TRUE),
('Aditya','Desai','aditya.desai@email.com','9810000015','Koregaon Park, Pune','Student','2022-08-01',TRUE),
('Kavya','Menon','kavya.menon@email.com','9810000016','Marine Drive, Kochi','Public','2022-08-20',TRUE),
('Manish','Tiwari','manish.tiwari@email.com','9810000017','Gomti Nagar, Lucknow','Faculty','2022-09-01',TRUE),
('Ritu','Bhardwaj','ritu.bhardwaj@email.com','9810000018','Sector 22, Chandigarh','Student','2022-09-15',FALSE),
('Suresh','Yadav','suresh.yadav@email.com','9810000019','Gachibowli, Hyderabad','Public','2022-10-01',TRUE),
('Tanvi','Shah','tanvi.shah@email.com','9810000020','Satellite, Ahmedabad','Student','2022-10-15',TRUE);

-- ---------------- STAFF (5) ----------------
INSERT INTO staff (first_name, last_name, email, role, hire_date) VALUES
('Lakshmi','Krishnan','lakshmi.k@library.org','Head Librarian','2020-06-01'),
('Deepak','Chauhan','deepak.c@library.org','Librarian','2021-01-15'),
('Farah','Khan','farah.k@library.org','Librarian','2021-07-01'),
('Naveen','Pillai','naveen.p@library.org','Assistant','2022-02-01'),
('Geeta','Saxena','geeta.s@library.org','Assistant','2022-08-01');

-- ---------------- BORROWING (30 transactions; mix of returned/active/overdue) ----------------
INSERT INTO borrowing (copy_id, member_id, issued_by, borrow_date, due_date, return_date) VALUES
(2,1,2,'2024-01-05','2024-01-19','2024-01-18'),
(4,2,2,'2024-01-10','2024-01-24','2024-02-01'),     -- returned late -> fine
(5,3,3,'2024-02-01','2024-02-22',NULL),             -- active (faculty 21-day)
(9,4,3,'2024-02-05','2024-02-19','2024-02-15'),
(11,5,2,'2024-02-10','2024-02-24','2024-03-05'),    -- late -> fine
(14,6,4,'2024-03-01','2024-03-22','2024-03-20'),
(16,7,2,'2024-03-05','2024-03-19',NULL),            -- overdue, not returned
(19,8,3,'2024-03-10','2024-03-24','2024-03-23'),
(21,9,4,'2024-03-15','2024-03-29','2024-04-10'),    -- late -> fine
(24,10,2,'2024-04-01','2024-04-22','2024-04-21'),
(27,11,3,'2024-04-05','2024-04-19',NULL),           -- overdue
(32,12,4,'2024-04-10','2024-04-24','2024-04-22'),
(34,13,2,'2024-04-15','2024-05-06','2024-05-04'),
(39,14,3,'2024-05-01','2024-05-15','2024-05-30'),   -- late -> fine
(2,5,2,'2024-05-10','2024-05-24','2024-05-23'),
(9,7,3,'2024-05-15','2024-05-29','2024-05-28'),
(11,9,4,'2024-06-01','2024-06-15','2024-06-14'),
(16,12,2,'2024-06-05','2024-06-19','2024-06-25'),   -- late -> fine
(19,14,3,'2024-06-10','2024-06-24','2024-06-22'),
(21,16,4,'2024-06-15','2024-06-29',NULL),           -- overdue
(24,17,2,'2024-07-01','2024-07-22','2024-07-20'),
(27,1,3,'2024-07-05','2024-07-19','2024-07-18'),
(32,3,4,'2024-07-10','2024-07-31','2024-07-29'),
(34,5,2,'2024-07-15','2024-08-05',NULL),            -- active
(39,8,3,'2024-08-01','2024-08-15','2024-08-14'),
(4,10,4,'2024-08-05','2024-08-26','2024-08-24'),
(5,11,2,'2024-08-10','2024-08-24','2024-09-02'),    -- late -> fine
(14,13,3,'2024-08-15','2024-09-05','2024-09-03'),
(16,15,4,'2024-09-01','2024-09-15','2024-09-13'),
(19,19,2,'2024-09-05','2024-09-19',NULL);           -- overdue

-- ---------------- FINE (7, tied to late returns / lost copy) ----------------
INSERT INTO fine (borrow_id, amount, reason, paid, paid_date) VALUES
(2,40.00,'Returned 8 days late',TRUE,'2024-02-02'),
(5,90.00,'Returned 10 days late',TRUE,'2024-03-06'),
(9,120.00,'Returned 12 days late',FALSE,NULL),
(14,150.00,'Returned 15 days late',TRUE,'2024-06-01'),
(18,60.00,'Returned 6 days late',FALSE,NULL),
(27,90.00,'Returned 9 days late',TRUE,'2024-09-03'),
(7,500.00,'Item not returned (overdue, presumed lost)',FALSE,NULL);

-- ---------------- RESERVATION (8) ----------------
INSERT INTO reservation (book_id, member_id, reserved_date, status) VALUES
(4,9,'2024-03-01','Pending'),
(7,11,'2024-03-15','Fulfilled'),
(4,16,'2024-04-01','Pending'),
(9,5,'2024-04-10','Cancelled'),
(17,13,'2024-05-01','Fulfilled'),
(6,2,'2024-05-15','Pending'),
(1,7,'2024-06-01','Fulfilled'),
(19,19,'2024-06-10','Pending');
-- =====================================================================
-- LIBRARY MANAGEMENT SYSTEM  --  File 3 of 4 : VIEWS
-- =====================================================================
USE library_db;

-- 1. Full book catalogue with publisher, category, and authors aggregated.
CREATE OR REPLACE VIEW vw_book_catalogue AS
SELECT  b.book_id,
        b.isbn,
        b.title,
        c.name  AS category,
        p.name  AS publisher,
        b.publication_year,
        b.price,
        GROUP_CONCAT(CONCAT(a.first_name,' ',a.last_name)
                     ORDER BY a.last_name SEPARATOR ', ') AS authors
FROM book b
JOIN category  c ON b.category_id  = c.category_id
JOIN publisher p ON b.publisher_id = p.publisher_id
LEFT JOIN book_author ba ON b.book_id = ba.book_id
LEFT JOIN author a       ON ba.author_id = a.author_id
GROUP BY b.book_id, b.isbn, b.title, c.name, p.name, b.publication_year, b.price;

-- 2. Live availability: copies per title and how many are available.
CREATE OR REPLACE VIEW vw_book_availability AS
SELECT  b.book_id,
        b.title,
        COUNT(bc.copy_id)                                            AS total_copies,
        SUM(bc.status = 'Available')                                 AS available_copies,
        SUM(bc.status = 'Borrowed')                                  AS borrowed_copies
FROM book b
LEFT JOIN book_copy bc ON b.book_id = bc.book_id
GROUP BY b.book_id, b.title;

-- 3. Currently borrowed (not yet returned) items with member + due date.
CREATE OR REPLACE VIEW vw_active_loans AS
SELECT  br.borrow_id,
        CONCAT(m.first_name,' ',m.last_name) AS member,
        m.membership_type,
        b.title,
        bc.barcode,
        br.borrow_date,
        br.due_date,
        DATEDIFF(CURDATE(), br.due_date)      AS days_overdue
FROM borrowing br
JOIN book_copy bc ON br.copy_id = bc.copy_id
JOIN book b       ON bc.book_id = b.book_id
JOIN member m     ON br.member_id = m.member_id
WHERE br.return_date IS NULL;

-- 4. Outstanding (unpaid) fines per member.
CREATE OR REPLACE VIEW vw_outstanding_fines AS
SELECT  m.member_id,
        CONCAT(m.first_name,' ',m.last_name) AS member,
        COUNT(f.fine_id)  AS unpaid_count,
        SUM(f.amount)     AS total_due
FROM fine f
JOIN borrowing br ON f.borrow_id = br.borrow_id
JOIN member m     ON br.member_id = m.member_id
WHERE f.paid = FALSE
GROUP BY m.member_id, member;
-- =====================================================================
-- LIBRARY MANAGEMENT SYSTEM  --  File 5 of 5 : TRIGGERS, STORED
-- PROCEDURES & TRANSACTIONS.  Run AFTER 01-04 (it operates on loaded data).
-- These move integrity logic into the database layer.
-- =====================================================================
USE library_db;

-- ---------------------------------------------------------------------
-- TRIGGERS
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_borrow_before_insert;
DROP TRIGGER IF EXISTS trg_borrow_after_insert;
DROP TRIGGER IF EXISTS trg_borrow_after_update;

DELIMITER //

-- 1. Block issuing a copy that is not Available (data integrity at DB layer).
CREATE TRIGGER trg_borrow_before_insert
BEFORE INSERT ON borrowing
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM book_copy WHERE copy_id = NEW.copy_id;
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Copy does not exist';
    ELSEIF v_status <> 'Available' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Copy is not available for borrowing';
    END IF;
END//

-- 2. When a loan is created, mark the copy Borrowed automatically.
CREATE TRIGGER trg_borrow_after_insert
AFTER INSERT ON borrowing
FOR EACH ROW
BEGIN
    UPDATE book_copy SET status = 'Borrowed' WHERE copy_id = NEW.copy_id;
END//

-- 3. When a loan is returned, free the copy and auto-create a fine if late.
CREATE TRIGGER trg_borrow_after_update
AFTER UPDATE ON borrowing
FOR EACH ROW
BEGIN
    DECLARE v_late INT;
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        UPDATE book_copy SET status = 'Available' WHERE copy_id = NEW.copy_id;
        SET v_late = DATEDIFF(NEW.return_date, NEW.due_date);
        IF v_late > 0 THEN
            INSERT INTO fine (borrow_id, amount, reason)
            VALUES (NEW.borrow_id, v_late * 10,
                    CONCAT('Returned ', v_late, ' day(s) late'))
            ON DUPLICATE KEY UPDATE amount = VALUES(amount), reason = VALUES(reason);
        END IF;
    END IF;
END//

-- ---------------------------------------------------------------------
-- STORED PROCEDURES  (encapsulate the transactional workflows)
-- ---------------------------------------------------------------------

-- Issue a book. Triggers handle availability check + status change.
CREATE PROCEDURE sp_issue_book(
    IN  p_copy_id   INT,
    IN  p_member_id INT,
    IN  p_staff_id  INT,
    IN  p_days      INT,
    OUT p_borrow_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
        INSERT INTO borrowing (copy_id, member_id, issued_by, borrow_date, due_date)
        VALUES (p_copy_id, p_member_id, p_staff_id,
                CURDATE(), DATE_ADD(CURDATE(), INTERVAL IFNULL(p_days,14) DAY));
        SET p_borrow_id = LAST_INSERT_ID();
    COMMIT;
END//

-- Return a book. Trigger frees the copy and applies any late fine.
CREATE PROCEDURE sp_return_book(IN p_borrow_id INT)
BEGIN
    DECLARE v_returned DATE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    SELECT return_date INTO v_returned FROM borrowing WHERE borrow_id = p_borrow_id;
    IF v_returned IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book already returned';
    END IF;
    START TRANSACTION;
        UPDATE borrowing SET return_date = CURDATE() WHERE borrow_id = p_borrow_id;
    COMMIT;
END//

-- Pay all outstanding fines for a member.
CREATE PROCEDURE sp_pay_member_fines(IN p_member_id INT)
BEGIN
    UPDATE fine f
    JOIN borrowing b ON f.borrow_id = b.borrow_id
    SET f.paid = TRUE, f.paid_date = CURDATE()
    WHERE b.member_id = p_member_id AND f.paid = FALSE;
END//

-- ---------------------------------------------------------------------
-- STORED FUNCTION : current outstanding fine total for a member.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_member_balance(p_member_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(10,2);
    SELECT COALESCE(SUM(f.amount),0) INTO v_total
    FROM fine f JOIN borrowing b ON f.borrow_id = b.borrow_id
    WHERE b.member_id = p_member_id AND f.paid = FALSE;
    RETURN v_total;
END//

DELIMITER ;

-- ---------------------------------------------------------------------
-- USAGE EXAMPLES (uncomment to test):
-- CALL sp_issue_book(13, 5, 2, 14, @bid);  SELECT @bid;
-- CALL sp_return_book(3);
-- CALL sp_pay_member_fines(9);
-- SELECT fn_member_balance(9) AS balance_due;
