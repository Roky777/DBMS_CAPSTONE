// MySQL connection pool, shared by the local server and Vercel functions.
// Works locally (Docker) and on cloud hosts. Railway exposes MYSQL* vars;
// other hosts use DB_* or a single connection URL (MYSQL_URL / DATABASE_URL).
// In serverless (Vercel) the pool is cached on globalThis so warm invocations
// reuse one pool instead of opening new connections every time.
const mysql = require('mysql2/promise');

function createPool() {
  const url = process.env.MYSQL_URL || process.env.DATABASE_URL;

  const base = {
    waitForConnections: true,
    connectionLimit: 5,
    queueLimit: 0,
    multipleStatements: true,  // needed for "CALL sp_issue_book(...); SELECT @bid"
    dateStrings: true,         // return DATE columns as 'YYYY-MM-DD' strings
  };

  if (url) {
    return mysql.createPool(Object.assign({ uri: url }, base, {
      ssl: process.env.DB_SSL === 'false' ? undefined : { rejectUnauthorized: false },
    }));
  }

  return mysql.createPool(Object.assign({
    host:     process.env.MYSQLHOST     || process.env.DB_HOST     || 'localhost',
    port:     process.env.MYSQLPORT     || process.env.DB_PORT     || 3306,
    user:     process.env.MYSQLUSER     || process.env.DB_USER     || 'root',
    password: process.env.MYSQLPASSWORD || process.env.DB_PASSWORD || 'root',
    database: process.env.MYSQLDATABASE || process.env.DB_NAME     || 'library_db',
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
  }, base));
}

const pool = globalThis.__libraryPool || (globalThis.__libraryPool = createPool());

module.exports = pool;
