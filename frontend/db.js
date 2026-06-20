// MySQL connection pool. Set your credentials here or via environment vars.
const mysql = require('mysql2/promise');

// Works locally (Docker) and on cloud hosts. Railway exposes MYSQL* vars;
// other hosts use DB_* or a single connection URL (MYSQL_URL / DATABASE_URL).
const url = process.env.MYSQL_URL || process.env.DATABASE_URL;

const base = {
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  multipleStatements: true,  // needed for "CALL sp_issue_book(...); SELECT @bid"
  dateStrings: true,         // return DATE columns as 'YYYY-MM-DD' strings
  // many cloud DBs require TLS; enable it unless explicitly disabled
  ssl: process.env.DB_SSL === 'false' ? undefined : { rejectUnauthorized: false }
};

const pool = url
  ? mysql.createPool(Object.assign({ uri: url }, base))
  : mysql.createPool(Object.assign({
      host:     process.env.MYSQLHOST     || process.env.DB_HOST     || 'localhost',
      port:     process.env.MYSQLPORT     || process.env.DB_PORT     || 3306,
      user:     process.env.MYSQLUSER     || process.env.DB_USER     || 'root',
      password: process.env.MYSQLPASSWORD || process.env.DB_PASSWORD || 'root',
      database: process.env.MYSQLDATABASE || process.env.DB_NAME     || 'library_db',
      // local Docker MySQL does not use TLS
      ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
    }, { ...base, ssl: undefined }));

module.exports = pool;
