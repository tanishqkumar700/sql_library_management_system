-- Task 1. Create a New Book Record -- '978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES 
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');


-- Task 2: Update an Existing Member's Address.
-- I have changed the address of Alice Johnson (C101) TO "321 Main St" from "123 Main St".
select * from issued_status;
UPDATE member 
	SET member_address = '321 Main St'
WHERE member_id = 'C101';


-- Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS122' from the issued_status table.

DELETE FROM issued_status
WHERE issued_id = 'IS122';


-- Task 4: Retrieve All Books Issued by a Specific Employee
 -- Objective: Select all books issued by the employee with emp_id = 'E101'.
 SELECT issued_book_name
 FROM issued_status
 WHERE issued_emp_id = 'E101';
 
 
 -- Task 5: List Members Who Have Issued More Than One Book
 -- Objective: Use GROUP BY to find members who have issued more than one book.
 SELECT 
	issued_member_id-- ,
    -- count(*) AS 'No. of books'
 FROM issued_status
 GROUP BY 1
 HAVING COUNT(*) > 1;
 
 
 -- Task 6: Create Summary Tables: 
 -- Used CTAS to generate new tables based on query results - each book and total book_issued_count**
 CREATE TABLE book_counts AS
	 SELECT 
		b.book_title,
		count(isu.issued_id) as no_of_issued
	 FROM books b
	 JOIN issued_status isu
		ON b.isbn = isu.issued_book_isbn
	GROUP BY 1;
    
    
 -- Task 7: Retrieve All Books in a Specific Category:
 -- i.e. 'Children','Classic','Dystopian','Fantasy','Fiction','Horror','History','Literary Fiction','Mystery','Science Fiction'
SELECT *
FROM books 
WHERE category = 'Fantasy';

 
 -- Task 8: Find Total Rental Income by Category:
 SELECT 
    category,
    SUM(rental_price),
    count(*)
 FROM books b
 JOIN issued_status isu
	ON b.isbn = isu.issued_book_isbn
 GROUP BY 1;
 
 
 -- Task 9: List Members Who Registered in the Last 180 Days:
 SELECT *
 FROM member
 WHERE reg_date >= current_date() - INTERVAL 180 day ;
 
 
 -- Task 10: List Employees with Their Branch Manager's Name and their branch details:
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
    
    
-- Task 11: Create a Table of Books with Rental Price Above a Certain Threshold (5 units):
CREATE TABLE premium_books AS 
	 SELECT *
	 FROM books 
	 WHERE rental_price > 5.00;
     
     
-- Task 12: Retrieve the List of Books Not Yet Returned:
SELECT 
	i.issued_id,
    i.issued_book_name
FROM issued_status i
LEFT JOIN return_status r
	ON i.issued_id = r.issued_id
WHERE r.return_id IS NULL;
 
 
 
 