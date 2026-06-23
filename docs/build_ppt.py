#!/usr/bin/env python3
# Generates docs/Athenaeum_Presentation.pptx — styled to match the Athenaeum theme.
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE
from pptx.oxml.ns import qn

# ---- palette (from style.css / walkthrough) ----
CREAM   = RGBColor(0xF4, 0xEC, 0xE0)
PAPER   = RGBColor(0xFB, 0xF6, 0xEE)
NAVY    = RGBColor(0x26, 0x41, 0x5E)
BLUE    = RGBColor(0x2F, 0x51, 0x70)
TERRA   = RGBColor(0xA8, 0x50, 0x3A)
INK     = RGBColor(0x2C, 0x2A, 0x26)
MUTED   = RGBColor(0x7A, 0x72, 0x63)
LINE    = RGBColor(0xEC, 0xE2, 0xD4)
WHITE   = RGBColor(0xFF, 0xFF, 0xFF)
SOFT    = RGBColor(0xF6, 0xEF, 0xE4)

SERIF = "Georgia"
SANS  = "Calibri"

prs = Presentation()
prs.slide_width  = Inches(13.333)
prs.slide_height = Inches(7.5)
SW, SH = prs.slide_width, prs.slide_height
BLANK = prs.slide_layouts[6]


def slide(bg=PAPER):
    s = prs.slides.add_slide(BLANK)
    r = s.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, SW, SH)
    r.fill.solid(); r.fill.fore_color.rgb = bg
    r.line.fill.background()
    r.shadow.inherit = False
    s.shapes._spTree.remove(r._element); s.shapes._spTree.insert(2, r._element)
    return s


def box(s, x, y, w, h):
    return s.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))


def rect(s, x, y, w, h, fill=None, line=None, line_w=1.0, shape=MSO_SHAPE.ROUNDED_RECTANGLE, radius=0.08):
    sp = s.shapes.add_shape(shape, Inches(x), Inches(y), Inches(w), Inches(h))
    if fill is None:
        sp.fill.background()
    else:
        sp.fill.solid(); sp.fill.fore_color.rgb = fill
    if line is None:
        sp.line.fill.background()
    else:
        sp.line.color.rgb = line; sp.line.width = Pt(line_w)
    sp.shadow.inherit = False
    if shape == MSO_SHAPE.ROUNDED_RECTANGLE:
        try:
            sp.adjustments[0] = radius
        except Exception:
            pass
    return sp


def text(tb, runs, align=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP, space=1.04):
    tf = tb.text_frame; tf.word_wrap = True; tf.vertical_anchor = anchor
    tf.margin_left = tf.margin_right = Pt(0); tf.margin_top = tf.margin_bottom = Pt(0)
    first = True
    for item in runs:
        txt, size, color, bold, font = (item + (None,) * 5)[:5]
        p = tf.paragraphs[0] if first else tf.add_paragraph()
        first = False
        p.alignment = align; p.line_spacing = space; p.space_after = Pt(4)
        r = p.add_run(); r.text = txt
        r.font.size = Pt(size); r.font.bold = bool(bold)
        r.font.color.rgb = color or INK
        r.font.name = font or SANS
    return tb


def bullets(tb, items, size=16, color=INK, gap=8, mark="—", mark_color=TERRA):
    tf = tb.text_frame; tf.word_wrap = True
    tf.margin_left = tf.margin_right = Pt(0); tf.margin_top = tf.margin_bottom = Pt(0)
    first = True
    for it in items:
        p = tf.paragraphs[0] if first else tf.add_paragraph()
        first = False
        p.line_spacing = 1.06; p.space_after = Pt(gap)
        rm = p.add_run(); rm.text = mark + "  "
        rm.font.size = Pt(size); rm.font.bold = True; rm.font.color.rgb = mark_color; rm.font.name = SANS
        # support (bold_lead, rest)
        if isinstance(it, tuple):
            lead, rest = it
            r1 = p.add_run(); r1.text = lead
            r1.font.size = Pt(size); r1.font.bold = True; r1.font.color.rgb = color; r1.font.name = SANS
            r2 = p.add_run(); r2.text = rest
            r2.font.size = Pt(size); r2.font.color.rgb = color; r2.font.name = SANS
        else:
            r = p.add_run(); r.text = it
            r.font.size = Pt(size); r.font.color.rgb = color; r.font.name = SANS
    return tb


def kicker(s, txt, x=0.9, y=0.62, color=TERRA):
    text(box(s, x, y, 9, 0.4), [(txt.upper(), 13, color, True, SANS)])


def title(s, txt, x=0.9, y=0.95, w=11.5, size=34, color=NAVY):
    text(box(s, x, y, w, 1.0), [(txt, size, color, True, SERIF)])


def accent_bar(s, x=0.92, y=1.72, w=0.9):
    rect(s, x, y, w, 0.06, fill=TERRA, shape=MSO_SHAPE.RECTANGLE)


def footer(s, n):
    text(box(s, 0.9, 7.02, 8, 0.35), [("Athenaeum · Library Management System", 10, MUTED, False, SANS)])
    t = box(s, 11.6, 7.02, 1.0, 0.35)
    text(t, [(str(n), 10, MUTED, False, SANS)], align=PP_ALIGN.RIGHT)


# ============================================================ 1 COVER
s = slide(NAVY)
# soft band
rect(s, 0, 4.65, 13.333, 2.85, fill=BLUE, shape=MSO_SHAPE.RECTANGLE)
text(box(s, 1.0, 0.7, 11, 0.5), [("DBMS CAPSTONE PROJECT", 15, RGBColor(0xD9,0xC7,0xB0), True, SANS)])
text(box(s, 1.0, 2.25, 11.3, 1.6), [("Athenaeum", 66, WHITE, True, SERIF)])
text(box(s, 1.0, 3.7, 11.3, 0.8), [("A Library Management System built on MySQL", 24, RGBColor(0xEC,0xE2,0xD4), False, SERIF)])
rect(s, 1.02, 3.55, 1.4, 0.05, fill=TERRA, shape=MSO_SHAPE.RECTANGLE)
bl = box(s, 1.0, 5.05, 11, 1.6)
bullets(bl, [
    ("What: ", "a normalized relational database with a live web front-end"),
    ("Stack: ", "MySQL · Node/Express · vanilla HTML/CSS/JS"),
    ("Hosted: ", "Vercel (app) + Aiven (database) — live on the internet"),
], size=16, color=RGBColor(0xF1,0xE7,0xD9), mark="›", mark_color=RGBColor(0xD9,0xC7,0xB0))
text(box(s, 1.0, 6.85, 11, 0.4), [("athenaeum-roky-pauls-projects.vercel.app", 13, RGBColor(0xC9,0xB6,0x9d), False, SANS)])

# ============================================================ 2 AGENDA
s = slide(); kicker(s, "Overview"); title(s, "What this presentation covers"); accent_bar(s)
items = [
    ("1 · What is it ", "— the problem and the goal"),
    ("2 · Why a library ", "— it exercises every relationship type"),
    ("3 · How we designed it ", "— ER model, keys, normalization to 3NF"),
    ("4 · What we built ", "— schema, data, views, queries, triggers, procedures"),
    ("5 · The application ", "— frontend, backend, 3-tier architecture"),
    ("6 · Walkthrough ", "— the build, step by step"),
    ("7 · Deployment ", "— hosting it online"),
    ("8 · Demo & summary", ""),
]
col = box(s, 1.1, 2.1, 11, 4.6)
bullets(col, items, size=18, gap=11)
footer(s, 2)

# ============================================================ 3 WHAT IS IT
s = slide(); kicker(s, "01 · The Idea"); title(s, "What is it?"); accent_bar(s)
text(box(s, 0.92, 2.0, 7.0, 2.6), [
    ("Athenaeum is a database-driven system that runs a library's daily work:",
     18, INK, False, SANS),
])
bl = box(s, 0.92, 2.7, 7.0, 4.0)
bullets(bl, [
    "Catalogue books, their authors, publishers and categories",
    "Track every physical copy and whether it is available",
    "Register members and library staff",
    "Issue and return books (borrow–return transactions)",
    "Charge fines automatically for late returns",
    "Let members reserve titles",
], size=17, gap=10)
# right card
rect(s, 8.4, 2.0, 4.0, 4.5, fill=SOFT, line=LINE, line_w=1.2, radius=0.05)
text(box(s, 8.75, 2.35, 3.3, 0.5), [("Core focus", 16, TERRA, True, SANS)])
bullets(box(s, 8.75, 2.95, 3.35, 3.4), [
    "Relational design",
    "Normalization (3NF)",
    "Referential integrity",
    "Borrow–return logic",
    "Advanced SQL",
], size=15, gap=10)
footer(s, 3)

# ============================================================ 4 WHY A LIBRARY
s = slide(); kicker(s, "02 · Rationale"); title(s, "Why a library system?"); accent_bar(s)
text(box(s, 0.92, 1.95, 11.4, 0.7), [
    ("A library naturally contains every relationship type the course requires:", 18, INK, False, SANS)])
cards = [
    ("1 : M", "One-to-Many", "A publisher has many books; a book has many copies.", NAVY),
    ("M : N", "Many-to-Many", "A book has many authors; an author writes many books.", TERRA),
    ("self", "Recursive", "A category can be a sub-category of another (Physics → Science).", BLUE),
    ("1 : 1", "One-to-One", "Each loan has at most one fine.", NAVY),
]
x = 0.92
for tag, name, desc, c in cards:
    rect(s, x, 2.8, 2.92, 3.4, fill=WHITE, line=LINE, line_w=1.2, radius=0.06)
    rect(s, x, 2.8, 2.92, 0.16, fill=c, shape=MSO_SHAPE.RECTANGLE)
    text(box(s, x+0.25, 3.15, 2.5, 0.9), [(tag, 30, c, True, SERIF)])
    text(box(s, x+0.25, 4.0, 2.5, 0.5), [(name, 16, INK, True, SANS)])
    text(box(s, x+0.25, 4.55, 2.45, 1.5), [(desc, 13.5, MUTED, False, SANS)])
    x += 3.06
footer(s, 4)

# ============================================================ 5 ARCHITECTURE
s = slide(); kicker(s, "03 · How it works"); title(s, "System architecture (3-tier)"); accent_bar(s)
text(box(s, 0.92, 1.95, 11.4, 0.7),
     [("A browser cannot talk to MySQL directly — a server sits in between.", 17, INK, False, SANS)])
tiers = [
    ("Presentation", "Browser\nHTML · CSS · JS", "renders dashboard,\ntables & forms", NAVY),
    ("Application", "Express API\n(Node.js)", "calls views &\nstored procedures", TERRA),
    ("Data", "MySQL\n(library_db)", "tables, views,\ntriggers, procedures", BLUE),
]
x = 1.15
for i, (lab, mid, sub, c) in enumerate(tiers):
    rect(s, x, 3.05, 3.3, 2.7, fill=WHITE, line=c, line_w=1.6, radius=0.06)
    text(box(s, x+0.2, 3.25, 2.9, 0.4), [(lab.upper(), 13, c, True, SANS)])
    text(box(s, x+0.2, 3.75, 2.9, 1.0), [(mid, 19, INK, True, SERIF)], space=1.0)
    text(box(s, x+0.2, 4.85, 2.9, 0.8), [(sub, 13, MUTED, False, SANS)], space=1.0)
    if i < 2:
        ar = s.shapes.add_shape(MSO_SHAPE.RIGHT_ARROW, Inches(x+3.32), Inches(4.15), Inches(0.55), Inches(0.5))
        ar.fill.solid(); ar.fill.fore_color.rgb = TERRA; ar.line.fill.background(); ar.shadow.inherit=False
    x += 3.87
text(box(s, 0.92, 6.15, 11.4, 0.7),
     [("We host the application on Vercel and the database on Aiven.", 15, MUTED, False, SANS)])
footer(s, 5)

# ============================================================ 6 DESIGN / NORMALIZATION
s = slide(); kicker(s, "03 · How we designed it"); title(s, "Schema design & normalization"); accent_bar(s)
text(box(s, 0.92, 1.95, 5.6, 0.5), [("11 tables, designed to 3rd Normal Form", 17, INK, True, SANS)])
bullets(box(s, 0.92, 2.55, 5.7, 4.2), [
    ("1NF ", "— atomic values; authors & copies moved to their own tables"),
    ("2NF ", "— no partial dependency on a composite key"),
    ("3NF ", "— no transitive dependency; publisher/category split out"),
    ("Keys ", "— surrogate primary keys, foreign keys everywhere"),
    ("Integrity ", "— PK, FK, UNIQUE, CHECK, ENUM, NOT NULL"),
], size=15.5, gap=12)
# right: table list
rect(s, 7.0, 2.1, 5.4, 4.7, fill=SOFT, line=LINE, line_w=1.2, radius=0.05)
text(box(s, 7.3, 2.3, 4.8, 0.4), [("The 11 tables", 15, TERRA, True, SANS)])
tbls = "publisher · category · author · book · book_author\nbook_copy · member · staff · borrowing · fine · reservation"
text(box(s, 7.3, 2.85, 4.85, 1.2), [(tbls, 14, INK, False, SANS)], space=1.25)
text(box(s, 7.3, 4.2, 4.8, 0.4), [("Why split book vs book_copy?", 14, TERRA, True, SANS)])
text(box(s, 7.3, 4.7, 4.85, 1.8), [
    ("A title's facts (ISBN, author, price) are stored once in book; each physical "
     "item lives in book_copy with its own barcode and status. No repeated data.", 13.5, MUTED, False, SANS)], space=1.12)
footer(s, 6)

# ============================================================ 7 WHAT WE BUILT (DB)
s = slide(); kicker(s, "04 · What we built"); title(s, "The database layer"); accent_bar(s)
blocks = [
    ("Schema", "sql/01_schema.sql", "11 tables · all constraints · indexes · ALTER demo"),
    ("Sample data", "sql/02_data.sql", "~200 meaningful rows (well over the 100 minimum)"),
    ("Views", "sql/03_views.sql", "catalogue, availability, active loans, outstanding fines"),
    ("Queries", "sql/04_queries.sql", "joins · subqueries · aggregates · GROUP BY / HAVING"),
    ("Procedures", "sql/05_procedures.sql", "3 triggers · 3 procedures · 1 function · transactions"),
]
y = 2.05
for name, file, desc in blocks:
    rect(s, 0.92, y, 11.5, 0.86, fill=WHITE, line=LINE, line_w=1.1, radius=0.12)
    text(box(s, 1.2, y+0.16, 2.3, 0.6), [(name, 17, NAVY, True, SERIF)])
    text(box(s, 3.5, y+0.2, 3.1, 0.5), [(file, 13, TERRA, True, SANS)])
    text(box(s, 6.7, y+0.2, 5.5, 0.5), [(desc, 13.5, MUTED, False, SANS)])
    y += 0.98
footer(s, 7)

# ============================================================ 8 INTEGRITY IN DB (triggers/proc)
s = slide(); kicker(s, "04 · What we built"); title(s, "Logic inside the database"); accent_bar(s)
text(box(s, 0.92, 1.95, 11.4, 0.6),
     [("Business rules live in MySQL, so data stays correct no matter how it is accessed.", 17, INK, False, SANS)])
two = [
    ("Triggers", [
        "Block issuing a copy that is not Available",
        "Auto-mark a copy 'Borrowed' when issued",
        "Auto-free the copy + create a fine on late return",
    ], TERRA),
    ("Procedures & transactions", [
        "sp_issue_book / sp_return_book / sp_pay_member_fines",
        "fn_member_balance() — outstanding dues",
        "Wrapped in transactions with ROLLBACK on error (ACID)",
    ], BLUE),
]
x = 0.92
for head, its, c in two:
    rect(s, x, 2.75, 5.65, 3.6, fill=WHITE, line=LINE, line_w=1.2, radius=0.05)
    rect(s, x, 2.75, 0.16, 3.6, fill=c, shape=MSO_SHAPE.RECTANGLE)
    text(box(s, x+0.4, 3.0, 5.0, 0.5), [(head, 19, NAVY, True, SERIF)])
    bullets(box(s, x+0.4, 3.7, 5.0, 2.5), its, size=15, gap=12)
    x += 5.95
footer(s, 8)

# ============================================================ 9 THE APP / FEATURES
s = slide(); kicker(s, "05 · The application"); title(s, "What the app does"); accent_bar(s)
feats = [
    ("Dashboard", "live counts of titles, members, loans & fines"),
    ("Catalogue", "searchable list with real-time availability"),
    ("Members", "directory with active / inactive status"),
    ("Issue book", "calls a stored procedure; trigger guards availability"),
    ("Active loans", "overdue highlighting + one-click return"),
    ("Fines", "outstanding dues per member, mark as paid"),
]
x, y = 0.92, 2.2
for i, (h, d) in enumerate(feats):
    cx = x + (i % 2) * 5.95
    cy = y + (i // 2) * 1.5
    rect(s, cx, cy, 5.65, 1.32, fill=WHITE, line=LINE, line_w=1.1, radius=0.1)
    text(box(s, cx+0.3, cy+0.18, 5.1, 0.5), [(h, 17, TERRA, True, SANS)])
    text(box(s, cx+0.3, cy+0.66, 5.1, 0.6), [(d, 14, MUTED, False, SANS)])
footer(s, 9)

# ============================================================ 10-12 WALKTHROUGH
def walkthrough_slide(n, phase_title, steps, page):
    s = slide(); kicker(s, "06 · Walkthrough")
    title(s, phase_title, size=30); accent_bar(s)
    y = 2.1
    for num, head, desc in steps:
        circ = s.shapes.add_shape(MSO_SHAPE.OVAL, Inches(0.95), Inches(y), Inches(0.55), Inches(0.55))
        circ.fill.solid(); circ.fill.fore_color.rgb = NAVY; circ.line.fill.background(); circ.shadow.inherit=False
        tf = circ.text_frame; tf.word_wrap=False
        p = tf.paragraphs[0]; p.alignment=PP_ALIGN.CENTER
        r = p.add_run(); r.text=str(num); r.font.size=Pt(15); r.font.bold=True; r.font.color.rgb=WHITE; r.font.name=SANS
        text(box(s, 1.75, y-0.04, 10.6, 0.5), [(head, 17, NAVY, True, SANS)])
        text(box(s, 1.75, y+0.42, 10.6, 0.6), [(desc, 13.5, MUTED, False, SANS)], space=1.05)
        y += 1.02
    footer(s, page)

walkthrough_slide(1, "Walkthrough · Plan & Design", [
    (1, "Understand the problem", "List what a library does; turn nouns into entities (tables)."),
    (2, "Map relationships", "Decide 1:M, M:N, recursive and 1:1 links between entities."),
    (3, "Draw the ER diagram", "Blueprint all 11 entities before writing any SQL."),
    (4, "Choose keys & normalize", "Surrogate primary keys; design straight to 3NF."),
], 10)

walkthrough_slide(2, "Walkthrough · Build the Database", [
    (5, "Create tables", "CREATE TABLE with PK, FK, UNIQUE, CHECK, ENUM constraints + indexes."),
    (6, "Insert sample data", "~200 rows; a deliberate mix of returned, active & overdue loans."),
    (7, "Create views", "Reusable queries for catalogue, availability, loans, fines."),
    (8, "Write advanced queries", "Joins, subqueries, aggregates, GROUP BY / HAVING."),
    (9, "Add triggers & procedures", "Move integrity + workflows into the database, in transactions."),
], 11)

walkthrough_slide(3, "Walkthrough · Build & Ship the App", [
    (10, "Backend API", "Express endpoints that read views and call stored procedures."),
    (11, "Frontend UI", "Vanilla HTML/CSS/JS — responsive, handmade-style design."),
    (12, "Connect with fetch()", "JSON over REST; database errors shown to the user."),
    (13, "Deploy online", "Database on Aiven, app on Vercel, configured via env vars."),
], 12)

# ============================================================ 13 DEPLOYMENT
s = slide(); kicker(s, "07 · Deployment"); title(s, "Hosting it online"); accent_bar(s)
steps = [
    ("Database → Aiven", "Created a free cloud MySQL and imported sql/init.sql (schema + data + views + procedures)."),
    ("App → Vercel", "Imported the GitHub repo; served as static frontend + serverless API."),
    ("Wiring", "Set MYSQL_URL and DB_SSL env vars in Vercel, then redeployed."),
    ("Result", "A public URL anyone can open — full frontend ↔ backend ↔ live database."),
]
y = 2.15
for h, d in steps:
    rect(s, 0.92, y, 11.5, 1.04, fill=WHITE, line=LINE, line_w=1.1, radius=0.1)
    rect(s, 0.92, y, 0.16, 1.04, fill=TERRA, shape=MSO_SHAPE.RECTANGLE)
    text(box(s, 1.3, y+0.16, 4.0, 0.6), [(h, 17, NAVY, True, SERIF)])
    text(box(s, 5.0, y+0.2, 7.2, 0.7), [(d, 14, MUTED, False, SANS)], space=1.06)
    y += 1.16
footer(s, 13)

# ============================================================ 14 TECH / DELIVERABLES
s = slide(); kicker(s, "Summary"); title(s, "Deliverables & tech"); accent_bar(s)
left = box(s, 0.92, 2.1, 5.7, 4.6)
text(left, [("Deliverables", 18, TERRA, True, SANS)])
bullets(box(s, 0.92, 2.7, 5.7, 4.0), [
    "Relational schema (3NF) + data dictionary",
    "SQL scripts: schema, data, views, queries, procedures",
    "~200 record sample dataset",
    "Working web application (frontend + API)",
    "Project report & step-by-step walkthrough (PDF)",
    "This presentation",
], size=15.5, gap=10)
rect(s, 7.0, 2.1, 5.4, 4.6, fill=SOFT, line=LINE, line_w=1.2, radius=0.05)
text(box(s, 7.3, 2.35, 4.8, 0.4), [("Technology", 18, TERRA, True, SANS)])
bullets(box(s, 7.3, 2.95, 4.85, 3.6), [
    ("Database: ", "MySQL 8 (InnoDB)"),
    ("Backend: ", "Node.js + Express"),
    ("Frontend: ", "HTML, CSS, JavaScript (no framework)"),
    ("Hosting: ", "Vercel + Aiven"),
    ("Source: ", "GitHub"),
], size=15.5, gap=12)
footer(s, 14)

# ============================================================ 15 CLOSING
s = slide(NAVY)
rect(s, 0, 0, 13.333, 7.5, fill=NAVY, shape=MSO_SHAPE.RECTANGLE)
text(box(s, 1.0, 2.5, 11.3, 1.2), [("Thank you", 54, WHITE, True, SERIF)])
rect(s, 1.02, 3.75, 1.4, 0.05, fill=TERRA, shape=MSO_SHAPE.RECTANGLE)
text(box(s, 1.0, 4.0, 11.3, 0.6), [("Athenaeum — Library Management System", 20, RGBColor(0xEC,0xE2,0xD4), False, SERIF)])
text(box(s, 1.0, 4.8, 11.3, 0.5), [("Live demo:  athenaeum-roky-pauls-projects.vercel.app", 15, RGBColor(0xC9,0xB6,0x9D), False, SANS)])
text(box(s, 1.0, 5.2, 11.3, 0.5), [("Questions & viva — happy to walk through the schema, queries, and live demo.", 14, RGBColor(0xC9,0xB6,0x9D), False, SANS)])

prs.save("Athenaeum_Presentation.pptx")
print("saved Athenaeum_Presentation.pptx ·", len(prs.slides.__iter__.__self__._sldIdLst), "slides")
