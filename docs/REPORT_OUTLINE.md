# Project Report & Presentation Outline
## Library Management System — DBMS Capstone

Use this as the skeleton for the **Project Report (PDF)** and **Slides (PPT/PDF)** deliverables.

---

## Part A — Report structure

1. **Title page** — project title, team members + roles, course, date.
2. **Abstract** — 1 paragraph: a MySQL library system managing books, copies, members, borrow/return, fines, reservations.
3. **Introduction** — problem statement, objectives, scope.
4. **Requirements** — functional (issue/return, search, fines, reservations) and non-functional (integrity, performance).
5. **ER Diagram** — paste the diagram from `docs/ER_DIAGRAM.md`; explain entities & relationships.
6. **Relational Schema** — the table list with PK/FK (from `01_schema.sql`).
7. **Normalization** — show 1NF → 2NF → 3NF with at least one worked example (see below).
8. **Data Dictionary** — from `docs/DATA_DICTIONARY.md`.
9. **Implementation** — describe tables, constraints, views, triggers, procedures, indexes (files `01`–`05`).
10. **Sample Queries & Output** — screenshots of the queries in `04_queries.sql` running in MySQL Workbench.
11. **Frontend** — screenshots of the running web app; explain the 3-tier architecture (browser → Express API → MySQL).
12. **Testing** — table of test cases (e.g. "issue an unavailable copy → blocked by trigger").
13. **Conclusion & Future work** — e.g. email reminders, role-based login.
14. **References**.

---

## Part B — Worked normalization example (for report + viva)

**Unnormalized idea:** one big `Loans` table holding member name, book title, author(s), publisher name, fine info.

- **1NF** — `author(s)` is multi-valued → violates atomicity. Fix: separate `author` table + `book_author` junction.
- **2NF** — in `book_author` (PK = book_id+author_id), book title depends only on book_id (partial dependency) → move title to `book`.
- **3NF** — in `book`, publisher city/country depend on publisher, not on book_id (transitive dependency) → move to `publisher`. Likewise fine details depend on the fine, not the loan → `fine` table.

Result: redundancy removed, no update/insert/delete anomalies.

---

## Part C — Slide deck (10–12 slides)

1. Title + team
2. Problem & objectives
3. ER diagram
4. Relational schema
5. Normalization (the worked example)
6. Constraints & integrity (PK/FK/CHECK/ENUM)
7. Views & indexes
8. Triggers & stored procedures (live integrity)
9. Advanced queries demo (1–2 screenshots)
10. Frontend demo screenshots + architecture
11. Testing summary
12. Conclusion & future work

---

## Part D — Likely viva questions (be ready)

- Why separate `book` from `book_copy`? → title-level data vs. physical inventory; supports many copies + per-copy status.
- Where is the M:N relationship? → `book_author` junction (composite PK).
- Show a recursive relationship. → `category.parent_id` self-FK.
- How is data integrity enforced without the app? → CHECK/FK constraints + triggers (`trg_borrow_before_insert` blocks unavailable copies; `trg_borrow_after_update` auto-creates fines).
- What does `sp_issue_book` do and why a transaction? → atomic insert + status change; rolls back on error.
- Difference between `WHERE` and `HAVING`? → row filter vs. group filter (see `04_queries.sql` B2/B4).
- Why indexes on `due_date`, `title`? → speed up overdue lookups and catalogue search.
- Can the browser connect to MySQL directly? → No; needs a backend (here Express) — hence 3-tier design.
- What normal form are you in and prove it. → 3NF; use the Part B example.
