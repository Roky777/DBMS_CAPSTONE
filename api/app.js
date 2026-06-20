// =====================================================================
// Express app (routes only — no app.listen). Shared by:
//   - server.js        (local dev: adds static + listen)
//   - api/index.js     (Vercel serverless: exports this app as the handler)
// Write operations go through stored procedures in 05_procedures.sql.
// =====================================================================
const express = require('express');
const pool = require('./db');

const app = express();
app.use(express.json());

const send = (res, sql, params = []) =>
  pool.query(sql, params)
      .then(([rows]) => res.json(rows))
      .catch(err => { console.error(err.message); res.status(500).json({ error: err.message }); });

// ---- Dashboard stats ----
app.get('/api/stats', async (req, res) => {
  try {
    const one = s => pool.query(s).then(([r]) => r[0].n);
    const [books, members, loans, fines] = await Promise.all([
      one('SELECT COUNT(*) n FROM book'),
      one('SELECT COUNT(*) n FROM member WHERE is_active = TRUE'),
      one('SELECT COUNT(*) n FROM borrowing WHERE return_date IS NULL'),
      one('SELECT COALESCE(SUM(amount),0) n FROM fine WHERE paid = FALSE'),
    ]);
    res.json({ books, members, active_loans: loans, outstanding_fines: fines });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// ---- Books: catalogue + availability (views) ----
app.get('/api/books', (req, res) => {
  const s = `%${req.query.search || ''}%`;
  send(res, `
    SELECT c.book_id, c.title, c.authors, c.category, c.publisher, c.price,
           a.total_copies, a.available_copies
    FROM vw_book_catalogue c
    JOIN vw_book_availability a ON c.book_id = a.book_id
    WHERE c.title LIKE ? OR c.authors LIKE ? OR c.category LIKE ?
    ORDER BY c.title`, [s, s, s]);
});

// ---- Members ----
app.get('/api/members', (req, res) =>
  send(res, `SELECT member_id, CONCAT(first_name,' ',last_name) AS name,
                    email, membership_type AS type, join_date AS join_d, is_active AS active
             FROM member ORDER BY first_name`));

// ---- Active loans (view) ----
app.get('/api/loans', (req, res) =>
  send(res, `SELECT * FROM vw_active_loans ORDER BY days_overdue DESC`));

// ---- Outstanding fines (view) ----
app.get('/api/fines', (req, res) =>
  send(res, `SELECT * FROM vw_outstanding_fines ORDER BY total_due DESC`));

// ---- Available copies for the Issue form ----
app.get('/api/available-copies', (req, res) =>
  send(res, `SELECT bc.copy_id, bc.barcode, b.title
             FROM book_copy bc JOIN book b ON bc.book_id = b.book_id
             WHERE bc.status = 'Available' ORDER BY b.title`));

// ---- Issue a book (stored procedure) ----
app.post('/api/loans', async (req, res) => {
  const { copy_id, member_id, days } = req.body;
  try {
    const [rows] = await pool.query(
      'CALL sp_issue_book(?, ?, ?, ?, @bid); SELECT @bid AS borrow_id;',
      [copy_id, member_id, 1, days || 14]);
    res.json({ ok: true, borrow_id: rows[rows.length - 1][0].borrow_id });
  } catch (e) { res.status(400).json({ error: e.message }); }
});

// ---- Return a book (stored procedure; trigger applies any late fine) ----
app.post('/api/loans/:id/return', async (req, res) => {
  try {
    await pool.query('CALL sp_return_book(?)', [req.params.id]);
    res.json({ ok: true });
  } catch (e) { res.status(400).json({ error: e.message }); }
});

// ---- Pay a member's fines (stored procedure) ----
app.post('/api/fines/:memberId/pay', async (req, res) => {
  try {
    await pool.query('CALL sp_pay_member_fines(?)', [req.params.memberId]);
    res.json({ ok: true });
  } catch (e) { res.status(400).json({ error: e.message }); }
});

module.exports = app;
