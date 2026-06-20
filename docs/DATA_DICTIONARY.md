# Data Dictionary — Library Management System (`library_db`)

Key: **PK** primary key · **FK** foreign key · **UQ** unique · **NN** not null

## publisher
| Column | Type | Constraints | Description |
|---|---|---|---|
| publisher_id | INT | PK, AUTO_INCREMENT | Unique publisher id |
| name | VARCHAR(120) | NN, UQ | Publisher name |
| address | VARCHAR(200) | | Street address |
| city | VARCHAR(60) | | City |
| country | VARCHAR(60) | DEFAULT 'India' | Country |
| contact_email | VARCHAR(120) | | Contact email |
| phone | VARCHAR(20) | | Contact phone |

## category
| Column | Type | Constraints | Description |
|---|---|---|---|
| category_id | INT | PK, AUTO_INCREMENT | Unique category id |
| name | VARCHAR(80) | NN, UQ | Category name |
| parent_id | INT | FK → category(category_id) | Parent category (self-reference; NULL = top level) |

## author
| Column | Type | Constraints | Description |
|---|---|---|---|
| author_id | INT | PK, AUTO_INCREMENT | Unique author id |
| first_name | VARCHAR(60) | NN | Given name |
| last_name | VARCHAR(60) | NN | Family name |
| nationality | VARCHAR(60) | | Nationality |
| birth_year | SMALLINT | CHECK 1000–2025 | Year of birth |

## book
| Column | Type | Constraints | Description |
|---|---|---|---|
| book_id | INT | PK, AUTO_INCREMENT | Unique title id |
| isbn | CHAR(13) | NN, UQ | ISBN-13 |
| title | VARCHAR(200) | NN | Book title |
| publisher_id | INT | NN, FK → publisher | Publisher |
| category_id | INT | NN, FK → category | Category |
| edition | VARCHAR(20) | | Edition |
| publication_year | SMALLINT | | Year published |
| language | VARCHAR(30) | DEFAULT 'English' | Language |
| price | DECIMAL(8,2) | CHECK ≥ 0 | List price |

## book_author (junction, M:N)
| Column | Type | Constraints | Description |
|---|---|---|---|
| book_id | INT | PK, FK → book | Book |
| author_id | INT | PK, FK → author | Author |
| author_role | VARCHAR(30) | DEFAULT 'Author' | Role (Author/Co-Author/Foreword) |

## book_copy
| Column | Type | Constraints | Description |
|---|---|---|---|
| copy_id | INT | PK, AUTO_INCREMENT | Unique physical copy id |
| book_id | INT | NN, FK → book | Title this copy belongs to |
| barcode | VARCHAR(30) | NN, UQ | Physical barcode |
| shelf_location | VARCHAR(30) | | Shelf code |
| status | ENUM | NN, DEFAULT 'Available' | Available/Borrowed/Reserved/Lost/Damaged |
| acquired_date | DATE | | Date acquired |

## member
| Column | Type | Constraints | Description |
|---|---|---|---|
| member_id | INT | PK, AUTO_INCREMENT | Unique member id |
| first_name | VARCHAR(60) | NN | Given name |
| last_name | VARCHAR(60) | NN | Family name |
| email | VARCHAR(120) | NN, UQ | Email |
| phone | VARCHAR(20) | | Phone |
| address | VARCHAR(200) | | Address |
| membership_type | ENUM | NN, DEFAULT 'Student' | Student/Faculty/Public |
| join_date | DATE | NN | Membership start |
| is_active | BOOLEAN | NN, DEFAULT TRUE | Active flag |
| last_updated | TIMESTAMP | auto | Row audit timestamp (added via ALTER) |

## staff
| Column | Type | Constraints | Description |
|---|---|---|---|
| staff_id | INT | PK, AUTO_INCREMENT | Unique staff id |
| first_name | VARCHAR(60) | NN | Given name |
| last_name | VARCHAR(60) | NN | Family name |
| email | VARCHAR(120) | NN, UQ | Email |
| role | VARCHAR(40) | DEFAULT 'Librarian' | Job role |
| hire_date | DATE | | Hire date |

## borrowing
| Column | Type | Constraints | Description |
|---|---|---|---|
| borrow_id | INT | PK, AUTO_INCREMENT | Unique loan id |
| copy_id | INT | NN, FK → book_copy | Copy loaned |
| member_id | INT | NN, FK → member | Borrower |
| issued_by | INT | FK → staff | Staff who issued |
| borrow_date | DATE | NN | Issue date |
| due_date | DATE | NN, CHECK ≥ borrow_date | Due date |
| return_date | DATE | CHECK ≥ borrow_date | Return date (NULL = still out) |

## fine
| Column | Type | Constraints | Description |
|---|---|---|---|
| fine_id | INT | PK, AUTO_INCREMENT | Unique fine id |
| borrow_id | INT | NN, UQ, FK → borrowing | Loan fined (1:1) |
| amount | DECIMAL(8,2) | NN, CHECK ≥ 0 | Fine amount |
| reason | VARCHAR(100) | | Reason |
| paid | BOOLEAN | NN, DEFAULT FALSE | Paid flag |
| paid_date | DATE | | Payment date |

## reservation
| Column | Type | Constraints | Description |
|---|---|---|---|
| reservation_id | INT | PK, AUTO_INCREMENT | Unique reservation id |
| book_id | INT | NN, FK → book | Reserved title |
| member_id | INT | NN, FK → member | Reserving member |
| reserved_date | DATE | NN | Reservation date |
| status | ENUM | NN, DEFAULT 'Pending' | Pending/Fulfilled/Cancelled |

## Database objects
- **Views:** vw_book_catalogue, vw_book_availability, vw_active_loans, vw_outstanding_fines
- **Triggers:** trg_borrow_before_insert (availability check), trg_borrow_after_insert (mark Borrowed), trg_borrow_after_update (free copy + auto-fine)
- **Procedures:** sp_issue_book, sp_return_book, sp_pay_member_fines
- **Function:** fn_member_balance(member_id)
- **Indexes:** idx_book_title, idx_book_category, idx_copy_status, idx_borrow_member, idx_borrow_due, idx_member_name
