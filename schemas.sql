
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