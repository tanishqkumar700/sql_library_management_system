# Library Management System — SQL Project

This project implements a Library Management System using SQL, covering database design, CRUD operations, CTAS (Create Table As Select), stored procedures, and advanced analytical queries.

Note from contributor:
- I have solved several core and intermediate tasks.
- I will continue by implementing and documenting the advanced tasks.

## Project Overview

- Project Title: Library Management System
- Level: Intermediate (progressing to Advanced)
- Database: `library_db`

This project demonstrates:
- Designing relational schema for a library system
- Managing tables and relationships
- Performing CRUD operations
- Writing CTAS for derived tables
- Creating stored procedures in PL/pgSQL
- Developing advanced queries for reporting and analytics

## Objectives

1. Set up the Library Management System database:
   - Tables: branches, employees, members, books, issued_status, return_status
2. CRUD Operations:
   - Create, Read, Update, Delete examples
3. CTAS:
   - Create summary tables from query results
4. Advanced SQL:
   - Complex queries for overdue detection, performance reports, and fines

## Project Structure

### 1. Database Setup

Database creation and schema:

```sql
-- LIBRARY MANAGEMENT SYSTEM --
create database sql_project_2;

-- CREATING TABLES 
drop table if exists branch;
create table branch 
	(
		branch_id varchar(10) primary key,
		manager_id varchar(10),
		branch_address varchar(30),
		contact_no varchar(20)
	);
    
drop table if exists employees;
create table employees
	(
		emp_id varchar(10) primary key,
		emp_name varchar(30),
		position varchar(30),
		salary int,
        branch_id varchar(10)  -- fk
	);

drop table if exists books;
create table books
	(
		isbn varchar(20) primary key,
		book_title varchar(70),
		category varchar(20),
		rental_price float,
        status varchar(10),
        author varchar(30),
        publisher varchar(50)
	);
    
drop table if exists member;
create table member
	(
		member_id varchar(10) primary key,
		member_name varchar(30),
		member_address varchar(50),
        reg_date date
	);
    
drop table if exists issued_status;
create table issued_status
	(
		issued_id varchar(10) primary key,
		issued_member_id varchar(10),  -- fk
		issued_book_name varchar(70),
        issued_date date,
        issued_book_isbn varchar(20),  -- fk
        issued_emp_id varchar(10)  -- fk
	);
    
    
drop table if exists return_status;
create table return_status
	(
		return_id varchar(10) primary key,
		issued_id varchar(10),  -- fk
		return_book_name varchar(70),
        return_date date,
        return_book_isbn varchar(20)
	);
    
    
    
-- FOREIGN KEY
ALTER TABLE issued_status
ADD CONSTRAINT fk_member
foreign key (issued_member_id)
references member(member_id);

ALTER TABLE issued_status
ADD CONSTRAINT fk_book
foreign key (issued_book_isbn)
references books(isbn);

ALTER TABLE issued_status
ADD CONSTRAINT fk_employee
foreign key (issued_emp_id)
references employees(emp_id);
    
    
ALTER TABLE employees
ADD CONSTRAINT fk_branch
foreign key (branch_id)
references branch(branch_id);


ALTER TABLE return_status
ADD CONSTRAINT fk_issued
foreign key (issued_id)
references issued_status(issued_id);
```

### 2. CRUD Operations

- Create: Task 1. Create a New Book Record -- '978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')".
```sql
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES 
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

SELECT * FROM books;
```

- Update: Task 2: Update the address of Alice Johnson (C101) TO "321 Main St" from "123 Main St".
```sql
UPDATE member 
	SET member_address = '321 Main St'
WHERE member_id = 'C101';
```

- Delete: Task 3: Delete the record with issued_id = 'IS122' from the issued_status table.
```sql
DELETE FROM issued_status
WHERE issued_id = 'IS121';
```

- Read: Task 4: Select all books issued by the employee with emp_id = 'E101'.
```sql
 SELECT issued_book_name
 FROM issued_status
 WHERE issued_emp_id = 'E101';
```

- Aggregation: Task 5: List Members Who Have Issued More Than One Book.
```sql
 SELECT 
	issued_member_id,
    count(*) AS 'No. of books'
 FROM issued_status
 GROUP BY 1
 HAVING COUNT(*) > 1;
```

### 3. CTAS (Create Table As Select)
CTAS: Task 6: Used CTAS to generate new tables based on query results - each book and total book_issued_counts.
```sql
 CREATE TABLE book_counts AS
	 SELECT 
		b.book_title,
		count(isu.issued_id) as no_of_issued
	 FROM books b
	 JOIN issued_status isu
		ON b.isbn = isu.issued_book_isbn
	GROUP BY 1;
```

### 4. Data Analysis & Findings

- Task 7: Retrieve All Books in a Specific Category.
```sql
SELECT * FROM books
WHERE category = 'Fantasy';
```

- Task 8: Find Total Rental Income by Category.
```sql
 SELECT 
    category,
    SUM(rental_price),
    count(*)
 FROM books b
 JOIN issued_status isu
	ON b.isbn = isu.issued_book_isbn
 GROUP BY 1;
 
```

- Task 9: List Members Who Registered in the Last 180 Days.
```sql
 SELECT *
 FROM member
 WHERE reg_date >= current_date() - INTERVAL 180 day ;
```

- Task 10: List Employees with Their Branch Manager's Name and their branch details.
```sql
 SELECT 
	e.emp_id,
    e.emp_name,
    br.*,
    em.emp_name as manager
 FROM employees e
 JOIN branch br 
	ON e.branch_id = br.branch_id
JOIN employees em
	ON br.manager_id = em.emp_id;
```

- CTAS: Task 11: Create a Table of Books with Rental Price Above a Certain Threshold (5 units)
```sql
CREATE TABLE premium_books AS 
	 SELECT *
	 FROM books 
	 WHERE rental_price > 5.00;
```

- Task 12: Retrieve the List of Books Not Yet Returned:
```sql
SELECT 
	i.issued_id,
    i.issued_book_name
FROM issued_status i
LEFT JOIN return_status r
	ON i.issued_id = r.issued_id
WHERE r.return_id IS NULL;
```

## SQL Files

- `schemas.sql` — Creates the database tables and foreign keys.
- `insert_query.sql` — Inserts sample data into all base tables.
- `query.sql` — Contains examples for:
	- Basic CRUD operations
	- CTAS (Create Table As Select)
	- Data Analysis & Findings (reporting queries)

## Reports

- Database Schema: Tables and relationships for branches, employees, members, books, issued, and returns.
- Data Analysis: Insights into categories, employee activity, member registrations, and issue/return status.
- Summary Reports: High-demand books, employee performance, branch revenue, and overdue fines.

## How to Use

1. Clone the Repository
```bash
git clone <https://github.com/tanishqkumar700/sql_library_management_system.git>
```

2. Set Up the Database
- Execute the SQL scripts (`schemas.sql and insert_query.sql`) to create and populate the database.

3. Run the Queries
- Use scripts like `query.sql` for analysis and reporting.

4. Explore and Modify
- Customize queries to explore additional insights or answer new questions.

## Notes

- Tested on MySQL; adjust syntax (e.g., intervals, procedures) if using other SQL dialects.
- Replace placeholder values with your data where needed.

