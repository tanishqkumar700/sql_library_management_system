# SQL Exercises and Solutions — 9SQL PROJECT 2

This README contains additional SQL exercises you can add to the project `9SQL PROJECT 2` and complete solutions for each exercise. The exercises are grouped by difficulty (Beginner → Advanced). Use them directly in `query.sql` as commented blocks, or run them against your database (CSV import into SQLite/MySQL/Postgres) to practice.

## Schema assumptions
These exercises assume the repository's CSVs / tables with the following (approximate) columns:

- `books` (isbn, book_title, category, rental_price, status, author, publisher)
- `members` (member_id, member_name, member_address, member_city, reg_date)
- `employees` (emp_id, emp_name, branch_id)
- `branch` (branch_id, branch_name, manager_id)
- `issued_status` (issued_id, issued_book_isbn, issued_book_name, issued_member_id, issued_emp_id, issued_date, due_date)
- `return_status` (return_id, issued_id, returned_date, condition)

Adjust column names as needed to match your concrete schema.

---

## Beginner

1) Find all books by a specific author (e.g. 'Harper Lee')

Description: List columns for books written by a chosen author.

Solution:

SELECT isbn, book_title, category, rental_price
FROM books
WHERE author = 'Harper Lee';


2) Count how many members live in each city

Solution:

SELECT member_city, COUNT(*) AS member_count
FROM members
GROUP BY member_city
ORDER BY member_count DESC;


3) List members whose names start with 'A'

Solution:

SELECT member_id, member_name, member_address
FROM members
WHERE member_name LIKE 'A%';


4) Increase rental price of all 'Fiction' books by 10% and show the updated rows

Solution (run inside a transaction if supported):

UPDATE books
SET rental_price = ROUND(rental_price * 1.10, 2)
WHERE category = 'Fiction';

-- Verify
SELECT isbn, book_title, category, rental_price
FROM books
WHERE category = 'Fiction';


5) Delete duplicate issued_status rows for the same member and isbn, keeping earliest issued_date (Postgres style)

Solution (Postgres using window function):

WITH ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY issued_member_id, issued_book_isbn ORDER BY issued_date) AS rn
  FROM issued_status
)
DELETE FROM issued_status
USING ranked
WHERE issued_status.issued_id = ranked.issued_id
  AND ranked.rn > 1;

(If your DB doesn't support DELETE ... USING, adapt with a subquery.)

---

## Intermediate

6) Top 5 most frequently issued books (by title)

Solution:

SELECT b.book_title, COUNT(isu.issued_id) AS issue_count
FROM books b
JOIN issued_status isu ON b.isbn = isu.issued_book_isbn
GROUP BY b.book_title
ORDER BY issue_count DESC
LIMIT 5;


7) Members with currently overdue books (not returned and due_date < today)

Solution:

SELECT m.member_id, m.member_name, isu.issued_id, isu.issued_book_name, isu.due_date,
       DATE_PART('day', CURRENT_DATE - isu.due_date) AS days_overdue
FROM issued_status isu
JOIN members m ON isu.issued_member_id = m.member_id
LEFT JOIN return_status r ON isu.issued_id = r.issued_id
WHERE r.issued_id IS NULL -- not returned
  AND isu.due_date < CURRENT_DATE;

(If using MySQL, replace DATE_PART with DATEDIFF(CURRENT_DATE, isu.due_date)).


8) For each branch, total number of books issued by employees of that branch

Solution:

SELECT br.branch_id, br.branch_name, COUNT(isu.issued_id) AS total_issued
FROM branch br
JOIN employees e ON br.branch_id = e.branch_id
JOIN issued_status isu ON e.emp_id = isu.issued_emp_id
GROUP BY br.branch_id, br.branch_name
ORDER BY total_issued DESC;


9) Members who have issued but never returned a book

Solution:

SELECT DISTINCT m.member_id, m.member_name, isu.issued_id, isu.issued_book_isbn
FROM issued_status isu
JOIN members m ON isu.issued_member_id = m.member_id
LEFT JOIN return_status r ON isu.issued_id = r.issued_id
WHERE r.issued_id IS NULL;


10) Books that have never been issued

Solution:

SELECT b.isbn, b.book_title
FROM books b
LEFT JOIN issued_status i ON b.isbn = i.issued_book_isbn
WHERE i.issued_id IS NULL;


11) Average rental price and count by category

Solution:

SELECT category, ROUND(AVG(rental_price),2) AS avg_price, COUNT(*) AS book_count
FROM books
GROUP BY category
ORDER BY book_count DESC;


12) For each member, latest issue date and total books issued

Solution:

SELECT m.member_id, m.member_name,
       MAX(isu.issued_date) AS last_issued_date,
       COUNT(isu.issued_id) AS total_issued
FROM members m
LEFT JOIN issued_status isu ON m.member_id = isu.issued_member_id
GROUP BY m.member_id, m.member_name
ORDER BY total_issued DESC;


13) Members who issued books from more than 2 distinct categories

Solution:

SELECT m.member_id, m.member_name, COUNT(DISTINCT b.category) AS distinct_categories
FROM issued_status isu
JOIN books b ON isu.issued_book_isbn = b.isbn
JOIN members m ON isu.issued_member_id = m.member_id
GROUP BY m.member_id, m.member_name
HAVING COUNT(DISTINCT b.category) > 2;

---

## Advanced

14) Daily issues for last 90 days with a 30-day rolling sum (Postgres example)

Solution:

WITH dates AS (
  SELECT generate_series(CURRENT_DATE - INTERVAL '89 day', CURRENT_DATE, INTERVAL '1 day')::date AS day
), daily AS (
  SELECT d.day, COALESCE(COUNT(isu.issued_id),0) AS issues_on_date
  FROM dates d
  LEFT JOIN issued_status isu ON DATE(isu.issued_date) = d.day
  GROUP BY d.day
)
SELECT day, issues_on_date,
       SUM(issues_on_date) OVER (ORDER BY day ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS rolling_30_day_sum
FROM daily
ORDER BY day;

(For MySQL use a derived table and window functions available in MySQL 8+; for SQLite you may need to emulate generate_series.)


15) Employee who issued the most books in each branch (branch top issuer)

Solution (Postgres / MySQL 8+):

WITH emp_counts AS (
  SELECT e.branch_id, e.emp_id, e.emp_name, COUNT(isu.issued_id) AS emp_issue_count
  FROM employees e
  LEFT JOIN issued_status isu ON e.emp_id = isu.issued_emp_id
  GROUP BY e.branch_id, e.emp_id, e.emp_name
)
SELECT branch_id, emp_id, emp_name, emp_issue_count
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY branch_id ORDER BY emp_issue_count DESC) AS rn
  FROM emp_counts
) t
WHERE rn = 1;


16) Create a view of active rentals (currently issued, not returned)

Solution:

CREATE OR REPLACE VIEW active_rentals AS
SELECT isu.issued_id, isu.issued_book_isbn, isu.issued_book_name AS book_title,
       isu.issued_member_id AS member_id, m.member_name,
       isu.issued_emp_id AS emp_id, e.emp_name,
       isu.issued_date, isu.due_date
FROM issued_status isu
JOIN members m ON isu.issued_member_id = m.member_id
JOIN employees e ON isu.issued_emp_id = e.emp_id
LEFT JOIN return_status r ON isu.issued_id = r.issued_id
WHERE r.issued_id IS NULL;

-- Then: SELECT * FROM active_rentals;


17) Members' lifetime rental spend: sum of rental_price at time of issue (join and aggregate)

Solution:

SELECT m.member_id, m.member_name, ROUND(SUM(b.rental_price),2) AS total_paid
FROM issued_status isu
JOIN books b ON isu.issued_book_isbn = b.isbn
JOIN members m ON isu.issued_member_id = m.member_id
GROUP BY m.member_id, m.member_name
ORDER BY total_paid DESC
LIMIT 10;


18) Identify books with increasing issue frequency: compare issues in last 60 days vs previous 60 days

Solution:

WITH counts AS (
  SELECT b.isbn, b.book_title,
    SUM(CASE WHEN isu.issued_date >= CURRENT_DATE - INTERVAL '60 day' THEN 1 ELSE 0 END) AS issues_last_60,
    SUM(CASE WHEN isu.issued_date >= CURRENT_DATE - INTERVAL '120 day' AND isu.issued_date < CURRENT_DATE - INTERVAL '60 day' THEN 1 ELSE 0 END) AS issues_prev_60
  FROM books b
  LEFT JOIN issued_status isu ON b.isbn = isu.issued_book_isbn
  GROUP BY b.isbn, b.book_title
)
SELECT isbn, book_title, issues_prev_60, issues_last_60,
       CASE WHEN issues_prev_60 = 0 AND issues_last_60 > 0 THEN NULL
            WHEN issues_prev_60 = 0 THEN 0
            ELSE ROUND( (issues_last_60::numeric - issues_prev_60) / issues_prev_60 * 100, 2) END AS pct_change
FROM counts
WHERE issues_last_60 > issues_prev_60
ORDER BY pct_change DESC NULLS LAST;

(Adjust casting syntax if not using Postgres.)


19) Find orphan issued_status rows whose issued_book_isbn does not exist in `books` (data integrity check)

Solution:

SELECT isu.issued_id, isu.issued_book_isbn
FROM issued_status isu
LEFT JOIN books b ON isu.issued_book_isbn = b.isbn
WHERE b.isbn IS NULL;


20) Stored-proc style pseudocode to mark a book returned (simple SQL steps)

Solution (pseudocode — adapt to your engine):

-- 1) Ensure issued_id exists and not already returned
-- 2) Insert into return_status
-- 3) Optionally update book status to available

-- Example (MySQL style):
START TRANSACTION;

-- Check not already returned (application logic recommended)
INSERT INTO return_status (issued_id, returned_date, condition)
VALUES ('IS123', CURRENT_DATE, 'good');

-- Optionally update book availability
UPDATE books b
SET status = 'yes'
WHERE b.isbn = (
  SELECT issued_book_isbn FROM issued_status WHERE issued_id = 'IS123'
);

COMMIT;

---

## Extra Challenges / Bonus

A) Division-style query: list members who have borrowed every book from a given small set (e.g., isbn in ('ISBN1','ISBN2','ISBN3')).

Solution sketch:

SELECT member_id
FROM issued_status
WHERE issued_book_isbn IN ('ISBN1','ISBN2','ISBN3')
GROUP BY member_id
HAVING COUNT(DISTINCT issued_book_isbn) = 3;


B) Add a foreign key constraint (data migration): ensure `issued_status.issued_book_isbn` references `books.isbn`

ALTER TABLE issued_status
ADD CONSTRAINT fk_issued_book
FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn);

(Ensure no orphan rows exist before adding the constraint.)

---

## How to use

- Paste these SQL blocks into your `query.sql` file as commented exercises or run them directly in your DB.
- If you want, I can append the commented versions into `query.sql` automatically, or generate a separate `exercises.sql` file with the answers included.
- Tell me which DB engine you use (SQLite, MySQL, Postgres) if you want engine-specific syntax adjustments.

---

## Next steps I can do for you

- Append all these exercises (as commented SQL) to `query.sql`.
- Create `exercises.sql` with runnable statements and a small shell script to load CSVs into a temporary SQLite database and run the queries.
- Adjust solutions for your DB engine (MySQL, Postgres, SQLite).

Which of these would you like next?