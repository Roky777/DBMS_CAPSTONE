// =====================================================================
// Athenaeum — vanilla JS frontend. Talks to the Express API, which
// reads/writes the live MySQL `library_db` (views + stored procedures).
// =====================================================================

const $ = id => document.getElementById(id);
const api = (p, opts) => fetch('/api' + p, opts).then(r => r.json());

// ---------- sidebar navigation ----------
document.querySelectorAll('.nav-item').forEach(item => {
  item.addEventListener('click', () => {
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
    item.classList.add('active');
    const id = item.dataset.tab;
    $(id).classList.add('active');
    loaders[id] && loaders[id]();
  });
});

// ---------- table helper ----------
function buildTable(el, rows, cols) {
  if (!rows || rows.error) { el.innerHTML = `<tr><td style="color:#a23b2e">⚠ ${rows?.error || 'Could not load'}</td></tr>`; return; }
  if (!rows.length) { el.innerHTML = '<tr><td>Nothing here yet.</td></tr>'; return; }
  const head = '<tr>' + cols.map(c => `<th>${c.label}</th>`).join('') + '</tr>';
  const body = rows.map(r => '<tr>' +
    cols.map(c => `<td>${c.render ? c.render(r) : (r[c.key] ?? '')}</td>`).join('') + '</tr>').join('');
  el.innerHTML = head + body;
}

// ---------- connection indicator ----------
function setConn(ok) {
  $('connDot').className = 'dot ' + (ok ? 'live' : 'down');
  $('connText').textContent = ok ? 'connected to database' : 'database unreachable';
}

// ---------- Overview ----------
async function loadDashboard() {
  const s = await api('/stats');
  setConn(!s.error);
  const cards = [
    { n: s.books, l: 'Titles in catalogue' },
    { n: s.members, l: 'Active members' },
    { n: s.active_loans, l: 'Books on loan' },
    { n: '₹' + Number(s.outstanding_fines || 0).toFixed(0), l: 'Outstanding fines' },
  ];
  $('statCards').innerHTML = cards.map(c =>
    `<div class="stat"><div class="n">${c.n ?? '—'}</div><div class="l">${c.l}</div></div>`).join('');
}

// ---------- Catalogue ----------
async function loadBooks() {
  const rows = await api('/books?search=' + encodeURIComponent($('bookSearch').value));
  buildTable($('booksTable'), rows, [
    { key:'title', label:'Title' },
    { key:'authors', label:'Author(s)' },
    { key:'category', label:'Subject' },
    { key:'publisher', label:'Publisher' },
    { label:'Price', render:r => '₹' + r.price },
    { label:'Copies', render:r =>
        `<span class="badge ${r.available_copies > 0 ? 'ok' : 'warn'}">${r.available_copies}/${r.total_copies} free</span>` },
  ]);
}
$('bookSearch').addEventListener('input', () => {
  clearTimeout(window._bt); window._bt = setTimeout(loadBooks, 250);
});

// ---------- Members ----------
async function loadMembers() {
  const rows = await api('/members');
  buildTable($('membersTable'), rows, [
    { key:'name', label:'Name' },
    { key:'email', label:'Email' },
    { key:'type', label:'Type' },
    { key:'join_d', label:'Joined' },
    { label:'Status', render:r =>
        `<span class="badge ${r.active ? 'ok' : 'warn'}">${r.active ? 'Active' : 'Inactive'}</span>` },
  ]);
}

// ---------- On Loan ----------
async function loadLoans() {
  const rows = await api('/loans');
  buildTable($('loansTable'), rows, [
    { key:'member', label:'Member' },
    { key:'title', label:'Book' },
    { key:'barcode', label:'Barcode' },
    { key:'borrow_date', label:'Taken' },
    { key:'due_date', label:'Due' },
    { label:'Status', render:r => r.days_overdue > 0
        ? `<span class="badge warn">${r.days_overdue} days late</span>` : '<span class="badge ok">on time</span>' },
    { label:'', render:r => `<button class="btn btn-sm" onclick="returnBook(${r.borrow_id})">Return</button>` },
  ]);
}
async function returnBook(id) {
  const res = await api(`/loans/${id}/return`, { method: 'POST' });
  if (res.error) return alert('Error: ' + res.error);
  alert('Returned. Any late fine was raised automatically by the database trigger.');
  loadLoans();
}

// ---------- Issue ----------
async function loadIssueForm() {
  const [copies, members] = await Promise.all([api('/available-copies'), api('/members')]);
  $('copySelect').innerHTML = (Array.isArray(copies) ? copies : []).map(c =>
    `<option value="${c.copy_id}">${c.title} · ${c.barcode}</option>`).join('')
    || '<option value="">No copies available</option>';
  $('memberSelect').innerHTML = (Array.isArray(members) ? members : []).filter(m => m.active).map(m =>
    `<option value="${m.member_id}">${m.name}</option>`).join('');
  $('issueMsg').textContent = '';
}
$('issueForm').addEventListener('submit', async e => {
  e.preventDefault();
  const body = {
    copy_id: +$('copySelect').value,
    member_id: +$('memberSelect').value,
    days: +$('daysInput').value,
  };
  const res = await api('/loans', {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });
  const msg = $('issueMsg');
  if (res.error) { msg.className = 'msg error'; msg.textContent = '✗ ' + res.error; }
  else { msg.className = 'msg success'; msg.textContent = '✓ Issued — loan #' + res.borrow_id + '.'; loadIssueForm(); }
});

// ---------- Fines ----------
async function loadFines() {
  const rows = await api('/fines');
  buildTable($('finesTable'), rows, [
    { key:'member', label:'Member' },
    { key:'unpaid_count', label:'Unpaid' },
    { label:'Total due', render:r => '₹' + r.total_due },
    { label:'', render:r => `<button class="btn btn-sm" onclick="payFine(${r.member_id})">Mark paid</button>` },
  ]);
}
async function payFine(memberId) {
  await api(`/fines/${memberId}/pay`, { method: 'POST' });
  loadFines();
}

// ---------- init ----------
const loaders = {
  dashboard: loadDashboard, books: loadBooks, members: loadMembers,
  loans: loadLoans, issue: loadIssueForm, fines: loadFines,
};
loadDashboard();
