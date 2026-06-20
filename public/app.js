// =====================================================================
// Vanilla JS frontend. Talks to the Express API, which reads/writes the
// live MySQL `library_db` (via views + stored procedures).
// =====================================================================

const $ = id => document.getElementById(id);
const api = (p, opts) => fetch('/api' + p, opts).then(r => r.json());

// ---------- Tab navigation ----------
document.querySelectorAll('.tab').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
    tab.classList.add('active');
    const id = tab.dataset.tab;
    $(id).classList.add('active');
    loaders[id] && loaders[id]();
  });
});

// ---------- Generic table builder ----------
function buildTable(el, rows, cols) {
  if (!rows || rows.error) { el.innerHTML = `<tr><td>⚠ ${rows?.error || 'Load error'}</td></tr>`; return; }
  if (!rows.length) { el.innerHTML = '<tr><td>No records found.</td></tr>'; return; }
  const head = '<tr>' + cols.map(c => `<th>${c.label}</th>`).join('') + '</tr>';
  const body = rows.map(r => '<tr>' +
    cols.map(c => `<td>${c.render ? c.render(r) : (r[c.key] ?? '')}</td>`).join('') + '</tr>').join('');
  el.innerHTML = head + body;
}

// ---------- Dashboard ----------
async function loadDashboard() {
  const s = await api('/stats');
  const cards = [
    { num: s.books, lbl: 'Total Book Titles' },
    { num: s.members, lbl: 'Active Members' },
    { num: s.active_loans, lbl: 'Active Loans' },
    { num: '₹' + Number(s.outstanding_fines || 0).toFixed(0), lbl: 'Outstanding Fines' },
  ];
  $('statCards').innerHTML = cards.map(c =>
    `<div class="card"><div class="num">${c.num ?? '—'}</div><div class="lbl">${c.lbl}</div></div>`).join('');
}

// ---------- Books (server-side search) ----------
async function loadBooks() {
  const rows = await api('/books?search=' + encodeURIComponent($('bookSearch').value));
  buildTable($('booksTable'), rows, [
    { key:'title', label:'Title' },
    { key:'authors', label:'Author(s)' },
    { key:'category', label:'Category' },
    { key:'publisher', label:'Publisher' },
    { label:'Price', render:r => '₹' + r.price },
    { label:'Available', render:r =>
        `<span class="badge ${r.available_copies > 0 ? 'ok' : 'warn'}">${r.available_copies}/${r.total_copies}</span>` },
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

// ---------- Active Loans ----------
async function loadLoans() {
  const rows = await api('/loans');
  buildTable($('loansTable'), rows, [
    { key:'member', label:'Member' },
    { key:'title', label:'Book' },
    { key:'barcode', label:'Barcode' },
    { key:'borrow_date', label:'Borrowed' },
    { key:'due_date', label:'Due' },
    { label:'Overdue', render:r => r.days_overdue > 0
        ? `<span class="badge warn">${r.days_overdue} d</span>` : '<span class="badge ok">On time</span>' },
    { label:'', render:r => `<button class="btn btn-sm" onclick="returnBook(${r.borrow_id})">Return</button>` },
  ]);
}
async function returnBook(id) {
  const res = await api(`/loans/${id}/return`, { method: 'POST' });
  if (res.error) return alert('Error: ' + res.error);
  alert('Book returned. Any late fine was applied automatically by the database trigger.');
  loadLoans();
}

// ---------- Issue Book ----------
async function loadIssueForm() {
  const [copies, members] = await Promise.all([api('/available-copies'), api('/members')]);
  $('copySelect').innerHTML = copies.map(c =>
    `<option value="${c.copy_id}">${c.title} (${c.barcode})</option>`).join('')
    || '<option value="">No copies available</option>';
  $('memberSelect').innerHTML = members.filter(m => m.active).map(m =>
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
  else { msg.className = 'msg success'; msg.textContent = '✓ Book issued (borrow #' + res.borrow_id + ').'; loadIssueForm(); }
});

// ---------- Fines ----------
async function loadFines() {
  const rows = await api('/fines');
  buildTable($('finesTable'), rows, [
    { key:'member', label:'Member' },
    { key:'unpaid_count', label:'Unpaid Fines' },
    { label:'Total Due', render:r => '₹' + r.total_due },
    { label:'', render:r => `<button class="btn btn-sm" onclick="payFine(${r.member_id})">Mark Paid</button>` },
  ]);
}
async function payFine(memberId) {
  await api(`/fines/${memberId}/pay`, { method: 'POST' });
  loadFines();
}

// ---------- Loader registry + initial load ----------
const loaders = {
  dashboard: loadDashboard, books: loadBooks, members: loadMembers,
  loans: loadLoans, issue: loadIssueForm, fines: loadFines,
};
loadDashboard();
