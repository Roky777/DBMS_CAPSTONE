# Deploying the Library Management System online (public URL)

We host two things: the **MySQL database** and the **Node app**. The easiest free option
that supports foreign keys is **Railway** (both can live in one project).

---

## Step 0 — Put the project on GitHub (one time)

```bash
cd /Users/rax/Desktop/DBMS_capstone_project
git init
git add .
git commit -m "Library Management System"
# create an empty repo on github.com, then:
git remote add origin https://github.com/<your-username>/library-management.git
git branch -M main
git push -u origin main
```
(`node_modules` is already excluded by `.gitignore`.)

---

## Step 1 — Create the Railway project + MySQL

1. Go to **railway.app** → sign in with GitHub → **New Project**.
2. Click **+ New** → **Database** → **Add MySQL**. Railway creates a MySQL service.
3. Open the MySQL service → **Variables** tab. Note these (Railway fills them automatically):
   `MYSQLHOST, MYSQLPORT, MYSQLUSER, MYSQLPASSWORD, MYSQLDATABASE, MYSQL_URL`.

## Step 2 — Load the schema + data into the cloud MySQL

The MySQL service has a **Connect** tab showing a public connection string. Use the combined
file `deploy/init.sql` from this repo:

```bash
# from your laptop — copy the values from Railway's MySQL "Connect" tab
mysql -h <MYSQLHOST> -P <MYSQLPORT> -u <MYSQLUSER> -p<MYSQLPASSWORD> < deploy/init.sql
```
> No local `mysql` client? Use Railway's web **Query** tab, or TablePlus / MySQL Workbench
> with the same host/port/user/password, then run the contents of `deploy/init.sql`.

`init.sql` creates the `library_db` database, all tables, ~200 rows, views, triggers and procedures.

## Step 3 — Deploy the Node app

1. In the same Railway project: **+ New** → **GitHub Repo** → pick your repo.
2. In that service's **Settings**:
   - **Root Directory:** `frontend`
   - **Start Command:** `npm start` (auto-detected)
3. In the service's **Variables**, add a reference to the database. Easiest:
   - `MYSQL_URL` = `${{MySQL.MYSQL_URL}}`  (Railway variable reference)
   - `DB_NAME` = `library_db`
   - `DB_SSL` = `false`  *(Railway internal network needs no TLS)*

   > If you used the **public** DB host instead of the internal one, set `DB_SSL=true`.

4. Railway builds and deploys. Open **Settings → Networking → Generate Domain** to get your
   public URL, e.g. `https://library-production.up.railway.app`.

## Step 4 — Test

Open the generated URL. The dashboard should show counts and the Books tab should list 25 titles.

---

## Deploying on Vercel (serverless) + external MySQL

The repo is already structured for Vercel: static frontend in `public/`, API in `api/`,
config in `vercel.json`. Vercel does **not** host MySQL, so you need an external database first.

1. **Create a cloud MySQL** (Railway or Aiven) and import `deploy/init.sql` into it
   (see Step 1–2 above). Note its host/port/user/password, or its connection URL.
2. Go to **vercel.com** → **Add New → Project** → import the GitHub repo `Roky777/DBMS_CAPSTONE`.
   Leave the framework as **Other**; the root directory is the repo root.
3. In **Settings → Environment Variables**, add the DB connection. Either a single URL:
   - `MYSQL_URL` = `mysql://user:pass@host:port/library_db`
   - `DB_SSL` = `true`   *(most cloud MySQL requires TLS)*

   …or the separate vars: `DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME=library_db, DB_SSL=true`.
4. Click **Deploy**. Vercel gives you a public URL like `https://dbms-capstone.vercel.app`.

> How it works: `vercel.json` serves `public/` statically and routes `/api/*` to the Express
> app exported by `api/index.js`. The pool in `api/db.js` is cached across warm invocations.
> No `PORT`/`app.listen` is used on Vercel — that's only for local `npm start`.

---

## Alternative: Render (app) + Aiven (MySQL)

- **Aiven** (aiven.io) → free MySQL → import `deploy/init.sql` (Aiven requires TLS, so keep `DB_SSL=true`).
- **Render** (render.com) → New **Web Service** from your GitHub repo →
  Root Directory `frontend`, Build `npm install`, Start `npm start`.
  Add env vars `DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME=library_db, DB_SSL=true`
  from Aiven's connection details.

---

## How the code supports this

`frontend/db.js` reads, in priority order:
1. `MYSQL_URL` / `DATABASE_URL` (single connection string), else
2. `MYSQLHOST/...` (Railway) or `DB_HOST/...` (generic), else
3. localhost defaults (your Docker setup).

`server.js` already listens on `process.env.PORT`, which every host sets automatically.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| App loads but tables empty | DB not imported (Step 2) or `DB_NAME` not `library_db` |
| `ER_ACCESS_DENIED` | wrong DB user/password env var |
| `ECONNREFUSED` / timeout | wrong host/port, or DB service asleep |
| `handshake ... SSL` error | toggle `DB_SSL` (`true` for public/Aiven, `false` for Railway internal) |
| App won't build | ensure Root Directory = `frontend` |
