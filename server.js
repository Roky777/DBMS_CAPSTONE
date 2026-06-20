// Local development server (Docker MySQL). On Vercel this file is NOT used —
// there the app runs as serverless functions via api/index.js + vercel.json.
const path = require('path');
const express = require('express');
const app = require('./api/app');

// serve the static frontend locally
app.use(express.static(path.join(__dirname, 'public')));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () =>
  console.log(`\n  Library Management System running at http://localhost:${PORT}\n`));
