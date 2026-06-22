# Athenaeum — Library Management System

A relational **Library Management System** for the DBMS capstone: a normalized MySQL
database (schema, views, triggers, stored procedures) with a vanilla HTML/CSS/JS
front-end served by a small Express API.

## Project structure

```
sql/            MySQL scripts
  01_schema.sql       tables, keys, constraints, indexes
  02_data.sql         ~200 sample rows
  03_views.sql        reporting views
  04_queries.sql      advanced query demos (joins, subqueries, group by)
  05_procedures.sql   triggers, stored procedures, transactions
  init.sql            all of the above combined (for cloud import)
public/         front-end (index.html, style.css, app.js)
api/            Express app (app.js), serverless entry (index.js), db pool (db.js)
server.js       local dev server  →  http://localhost:3000
docker-compose.yml   one-command local MySQL (auto-loads sql/)
vercel.json     serverless config for hosting on Vercel
docs/           Project_Report.pdf, Walkthrough.pdf
```

## Run it locally (Docker)

```bash
docker compose up -d        # starts MySQL and loads sql/ automatically
npm install                 # once
npm start                   # → http://localhost:3000
```
Stop: `docker compose down` · Reset data: `docker compose down -v && docker compose up -d`

## Host it online

The app is Vercel-ready, but **Vercel does not host MySQL** — you need an external
database first (Railway or Aiven both run real MySQL with foreign-key support).

1. **Create a cloud MySQL** and import `sql/init.sql` into it. Using Docker as the client:
   ```bash
   docker run --rm -i -v "$PWD/sql:/s" mysql:8.0 \
     sh -c "mysql -h HOST -P PORT -u USER -pPASSWORD < /s/init.sql"
   ```
2. **Import the repo on Vercel** (Framework = Other).
3. **Set environment variables** in Vercel, then redeploy:
   | Name | Value |
   |------|-------|
   | `MYSQL_URL` | `mysql://user:pass@host:port/library_db` |
   | `DB_SSL` | `true` (Aiven) or `false` (Railway public proxy) |
4. Open the generated URL. Check `…/api/books` returns the book list.

## Database design at a glance

11 tables in 3NF. Relationships: 1:M (publisher→book), M:N (book↔author via
`book_author`), recursive (`category.parent_id`), and 1:1 (`fine.borrow_id` unique).
Integrity lives in the database: constraints + triggers (auto status change, auto late
fine) + stored procedures wrapped in transactions.
