# Library Management System — DBMS Capstone

MySQL backend for a library managing books, publishers, authors, members, and borrow/return operations.

## Project layout

```
01_schema.sql       tables, constraints, indexes, ALTER
02_data.sql         sample data (~200 records)
03_views.sql        4 views
04_queries.sql      advanced query demonstrations
05_procedures.sql   triggers, stored procedures, function, transactions
frontend/           Node/Express API + vanilla HTML/CSS/JS UI (3-tier)
docs/               ER diagram, data dictionary, report & viva outline
```

## 1. Set up the database (run in order)

```bash
mysql -u root -p < 01_schema.sql
mysql -u root -p < 02_data.sql
mysql -u root -p < 03_views.sql
mysql -u root -p < 05_procedures.sql   # triggers + procedures (load before using the app)
mysql -u root -p < 04_queries.sql      # optional: see the query demos run
```

## 2. Run the web app (frontend + live MySQL)

```bash
# from the project root
npm install      # already done
npm start        # -> http://localhost:3000
```

Easiest local DB is Docker: `docker compose up -d` then `npm start`.

## Project structure

```
public/        vanilla HTML/CSS/JS frontend
api/           Express app (app.js), serverless entry (index.js), db pool (db.js)
server.js      local dev server (serves public/ + listens on :3000)
vercel.json    serverless config for Vercel deployment
deploy/init.sql combined schema+data+views+procedures for cloud import
```

The browser (vanilla HTML/CSS/JS) calls the Express API, which reads/writes the
**live MySQL `library_db`** through the views and stored procedures. This is a
standard **3-tier architecture** — a browser cannot connect to MySQL directly.

Or inside the MySQL client: `SOURCE 01_schema.sql;` etc. (run in order).

## Entities & Relationships

| Relationship | Type | Implementation |
|---|---|---|
| Publisher → Book | 1 : M | `book.publisher_id` FK |
| Category → Book | 1 : M | `book.category_id` FK |
| Category → Category | 1 : M (recursive) | `category.parent_id` self-FK |
| Book ↔ Author | M : N | junction `book_author` |
| Book → BookCopy | 1 : M | `book_copy.book_id` FK |
| Member → Borrowing | 1 : M | `borrowing.member_id` FK |
| BookCopy → Borrowing | 1 : M | `borrowing.copy_id` FK |
| Staff → Borrowing | 1 : M | `borrowing.issued_by` FK |
| Borrowing → Fine | 1 : 1 | `fine.borrow_id` UNIQUE FK |
| Member/Book → Reservation | 1 : M | `reservation` FKs |

A physical copy (`book_copy`) is separated from the title (`book`) so the same title can have many copies, each independently Available / Borrowed / Lost.

## Normalization (to 3NF)

- **1NF** — all attributes atomic; repeating groups (multiple authors, multiple copies) moved to their own tables (`book_author`, `book_copy`).
- **2NF** — no partial dependency. In the M:N junction `book_author` (composite PK) the only attribute, `author_role`, depends on the whole key.
- **3NF** — no transitive dependencies. Publisher details live in `publisher` (not repeated in `book`); category names in `category`; fine data in `fine` rather than in `borrowing`. Non-key attributes depend only on their table's key.

## Constraints used

PRIMARY KEY, FOREIGN KEY (with RESTRICT / CASCADE / SET NULL rules), UNIQUE (isbn, barcode, email), NOT NULL, DEFAULT, CHECK (price ≥ 0, due_date ≥ borrow_date, birth_year range), and ENUM for status fields.

## Mandatory SQL coverage

- **Queries (`04_queries.sql`):** joins (inner / left / self), nested & correlated subqueries (EXISTS, NOT IN, scalar), aggregates (COUNT/SUM/AVG), GROUP BY … HAVING, view usage, UPDATE/DELETE inside a transaction.
- **DB-layer logic (`05_procedures.sql`):** 3 triggers (availability check, auto status change, auto-fine on late return), 3 stored procedures (`sp_issue_book`, `sp_return_book`, `sp_pay_member_fines`), a stored function (`fn_member_balance`), and transactions with rollback handlers.

## Documentation (in `docs/`)

`ER_DIAGRAM.md` (Mermaid + cardinality table), `DATA_DICTIONARY.md` (every column + constraint), `REPORT_OUTLINE.md` (report structure, normalization worked example, slide deck, and likely viva questions with answers).

## Record count (>100)

10 publishers · 12 categories · 20 authors · 25 books · ~24 book_author links · 40 copies · 20 members · 5 staff · 30 borrowings · 7 fines · 8 reservations = **~200 records**.
