-- =====================================================================
-- LIBRARY MANAGEMENT SYSTEM  --  File 4 of 4 : ADVANCED SQL QUERIES
-- Covers every mandatory category: JOINs, nested/subqueries,
-- aggregate functions, GROUP BY ... HAVING, views, UPDATE/DELETE.
-- =====================================================================
USE library_db;

-- =========================================================
-- A. JOINS
-- =========================================================

-- A1. Every borrowing with member name, book title and issuing staff (multi-table INNER JOIN).
SELECT br.borrow_id,
       CONCAT(m.first_name,' ',m.last_name)  AS member,
       b.title,
       CONCAT(s.first_name,' ',s.last_name)  AS issued_by,
       br.borrow_date, br.return_date
FROM borrowing br
JOIN book_copy bc ON br.copy_id   = bc.copy_id
JOIN book b       ON bc.book_id   = b.book_id
JOIN member m     ON br.member_id = m.member_id
LEFT JOIN staff s ON br.issued_by = s.staff_id
ORDER BY br.borrow_id;

-- A2. LEFT JOIN: members who have NEVER borrowed a book.
SELECT m.member_id, CONCAT(m.first_name,' ',m.last_name) AS member
FROM member m
LEFT JOIN borrowing br ON m.member_id = br.member_id
WHERE br.borrow_id IS NULL;

-- A3. SELF JOIN on the recursive category hierarchy (child -> parent).
SELECT child.name AS subcategory, parent.name AS parent_category
FROM category child
JOIN category parent ON child.parent_id = parent.category_id;

-- =========================================================
-- B. AGGREGATE FUNCTIONS + GROUP BY / HAVING
-- =========================================================

-- B1. Number of books and average price per category.
SELECT c.name AS category,
       COUNT(b.book_id) AS num_books,
       ROUND(AVG(b.price),2) AS avg_price
FROM category c
JOIN book b ON c.category_id = b.category_id
GROUP BY c.name
ORDER BY num_books DESC;

-- B2. Most-borrowed books (GROUP BY + HAVING to show only popular titles).
SELECT b.title,
       COUNT(br.borrow_id) AS times_borrowed
FROM book b
JOIN book_copy bc ON b.book_id = bc.book_id
JOIN borrowing br ON bc.copy_id = br.copy_id
GROUP BY b.book_id, b.title
HAVING COUNT(br.borrow_id) >= 2
ORDER BY times_borrowed DESC;

-- B3. Total fine collected vs outstanding.
SELECT SUM(CASE WHEN paid THEN amount ELSE 0 END)     AS collected,
       SUM(CASE WHEN NOT paid THEN amount ELSE 0 END) AS outstanding,
       COUNT(*)                                       AS total_fines
FROM fine;

-- B4. Borrowings per member, only members with more than 2 loans (HAVING).
SELECT CONCAT(m.first_name,' ',m.last_name) AS member,
       COUNT(br.borrow_id) AS loan_count
FROM member m
JOIN borrowing br ON m.member_id = br.member_id
GROUP BY m.member_id, member
HAVING COUNT(br.borrow_id) > 2
ORDER BY loan_count DESC;

-- =========================================================
-- C. NESTED / SUBQUERIES
-- =========================================================

-- C1. Books priced above the overall average price (scalar subquery).
SELECT title, price
FROM book
WHERE price > (SELECT AVG(price) FROM book)
ORDER BY price DESC;

-- C2. Members who currently have at least one OVERDUE book (correlated subquery + EXISTS).
SELECT m.member_id, CONCAT(m.first_name,' ',m.last_name) AS member
FROM member m
WHERE EXISTS (
    SELECT 1 FROM borrowing br
    WHERE br.member_id = m.member_id
      AND br.return_date IS NULL
      AND br.due_date < CURDATE()
);

-- C3. Books that have never been borrowed (NOT IN subquery).
SELECT title
FROM book
WHERE book_id NOT IN (
    SELECT bc.book_id
    FROM book_copy bc
    JOIN borrowing br ON bc.copy_id = br.copy_id
);

-- C4. Category with the highest number of books (subquery in HAVING / derived table).
SELECT category, num_books FROM (
    SELECT c.name AS category, COUNT(b.book_id) AS num_books
    FROM category c JOIN book b ON c.category_id = b.category_id
    GROUP BY c.name
) t
WHERE num_books = (
    SELECT MAX(cnt) FROM (
        SELECT COUNT(*) AS cnt FROM book GROUP BY category_id
    ) x
);

-- =========================================================
-- D. VIEW USAGE
-- =========================================================
SELECT * FROM vw_book_catalogue      ORDER BY title LIMIT 10;
SELECT * FROM vw_book_availability   WHERE available_copies = 0;
SELECT * FROM vw_active_loans        WHERE days_overdue > 0 ORDER BY days_overdue DESC;
SELECT * FROM vw_outstanding_fines   ORDER BY total_due DESC;

-- =========================================================
-- E. UPDATE / DELETE demonstrations
-- =========================================================

-- E1. Mark an unpaid fine as paid.
UPDATE fine
SET paid = TRUE, paid_date = CURDATE()
WHERE fine_id = 3;

-- E2. Return a book: set return date and free the copy (would normally be a transaction).
START TRANSACTION;
UPDATE borrowing SET return_date = CURDATE() WHERE borrow_id = 3 AND return_date IS NULL;
UPDATE book_copy SET status = 'Available'
WHERE copy_id = (SELECT copy_id FROM borrowing WHERE borrow_id = 3);
COMMIT;

-- E3. Deactivate members inactive (no loans) — soft delete via UPDATE.
UPDATE member
SET is_active = FALSE
WHERE member_id IN (
    SELECT member_id FROM (
        SELECT m.member_id
        FROM member m
        LEFT JOIN borrowing br ON m.member_id = br.member_id
        WHERE br.borrow_id IS NULL
    ) inactive
);

-- E4. Delete cancelled reservations.
DELETE FROM reservation WHERE status = 'Cancelled';
