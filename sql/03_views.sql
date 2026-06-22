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
