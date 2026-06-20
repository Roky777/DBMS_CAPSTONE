# ER Diagram — Library Management System

Rendered with Mermaid (GitHub/VS Code preview shows it visually). A crow's-foot
ER diagram of all 11 entities and their relationships.

```mermaid
erDiagram
    PUBLISHER ||--o{ BOOK : publishes
    CATEGORY  ||--o{ BOOK : classifies
    CATEGORY  ||--o{ CATEGORY : "parent of"
    BOOK      ||--o{ BOOK_COPY : "has copies"
    BOOK      }o--o{ AUTHOR : "written by"
    BOOK_AUTHOR }o--|| BOOK : ""
    BOOK_AUTHOR }o--|| AUTHOR : ""
    BOOK_COPY ||--o{ BORROWING : "is loaned in"
    MEMBER    ||--o{ BORROWING : borrows
    STAFF     ||--o{ BORROWING : issues
    BORROWING ||--o| FINE : "may incur"
    BOOK      ||--o{ RESERVATION : "reserved as"
    MEMBER    ||--o{ RESERVATION : reserves

    PUBLISHER {
        int publisher_id PK
        varchar name
        varchar city
        varchar country
    }
    CATEGORY {
        int category_id PK
        varchar name
        int parent_id FK
    }
    AUTHOR {
        int author_id PK
        varchar first_name
        varchar last_name
        smallint birth_year
    }
    BOOK {
        int book_id PK
        char isbn
        varchar title
        int publisher_id FK
        int category_id FK
        decimal price
    }
    BOOK_AUTHOR {
        int book_id PK,FK
        int author_id PK,FK
        varchar author_role
    }
    BOOK_COPY {
        int copy_id PK
        int book_id FK
        varchar barcode
        enum status
    }
    MEMBER {
        int member_id PK
        varchar first_name
        varchar last_name
        varchar email
        enum membership_type
        boolean is_active
    }
    STAFF {
        int staff_id PK
        varchar first_name
        varchar last_name
        varchar role
    }
    BORROWING {
        int borrow_id PK
        int copy_id FK
        int member_id FK
        int issued_by FK
        date borrow_date
        date due_date
        date return_date
    }
    FINE {
        int fine_id PK
        int borrow_id FK
        decimal amount
        boolean paid
    }
    RESERVATION {
        int reservation_id PK
        int book_id FK
        int member_id FK
        enum status
    }
```

## Relationship summary (cardinality & participation)

| Relationship | Cardinality | Participation |
|---|---|---|
| Publisher–Book | 1 : M | Book total (every book has a publisher); Publisher partial |
| Category–Book | 1 : M | Book total; Category partial |
| Category–Category | 1 : M (recursive) | both partial (parent optional) |
| Book–Author | M : N (via BOOK_AUTHOR) | both partial |
| Book–BookCopy | 1 : M | BookCopy total |
| BookCopy–Borrowing | 1 : M | Borrowing total |
| Member–Borrowing | 1 : M | Borrowing total; Member partial |
| Staff–Borrowing | 1 : M | Borrowing partial (issued_by nullable) |
| Borrowing–Fine | 1 : 1 (0..1) | Fine total; Borrowing partial |
| Book/Member–Reservation | 1 : M | Reservation total |
