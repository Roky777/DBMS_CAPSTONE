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
