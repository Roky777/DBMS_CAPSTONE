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
