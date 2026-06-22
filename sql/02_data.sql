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
