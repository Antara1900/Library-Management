
Create database Library;
use Library;
-- 1. List all books with their author names
select b.title, a.name
 from authors a
inner join books b
on a.author_id = b.author_id;

-- 2. Find all members who joined in 2025
select member_id, name, join_date from members
where year(join_date)=2025;

-- 3. Count how many books are available in each category
select c.category_name, count(b.title) `numbers of books`
from categories c
inner join books b
on c.category_id = b.category_id
group by c.category_name;

-- 4.Find the top 5 most borrowed books
select b.title , count(br.borrow_id) `borrowed number`
from books b
inner join borrow_records br
on b.book_id = br.book_id
group by b.title
order by count(br.borrow_id)
limit 5;

-- 5. List overdue books that have not been returned
SELECT m.name AS member, b.title, br.due_date
FROM borrow_records br
JOIN members m ON br.member_id = m.member_id
JOIN books b ON br.book_id = b.book_id
WHERE br.return_date IS NULL
  AND br.due_date < CURRENT_DATE;
  
  -- 6. Find members who have borrowed more than 10 books
  select  m.name, count(b.borrow_id) as `Total Borrowed Books` from members m
  join borrow_records b 
  on m.member_id = b.member_id
  group by m.name
  having count(b.borrow_id)>10;
  
  -- 7.Find members who have borrowed books from at least 3 different categories 
  select m.name , count(distinct b.category_id) from members m
  join borrow_records br 
  on m.member_id=br.member_id
  join books b
  on b.book_id = br.book_id
  group by m.name
  having count(distinct b.category_id)>=3;
  
  -- 8.Show top 3 authors whose books are borrowed the most
  SELECT a.name AS author, COUNT(br.borrow_id) AS borrow_count
FROM borrow_records br
JOIN books b ON br.book_id = b.book_id
JOIN authors a ON b.author_id = a.author_id
GROUP BY a.name
ORDER BY borrow_count DESC
LIMIT 3;

-- 9.Find books that have never been borrowed
SELECT b.title
FROM books b
LEFT JOIN borrow_records br
 ON b.book_id = br.book_id
WHERE br.book_id IS NULL;

-- 10.List members who have returned all books they borrowed (no pending books)
SELECT m.name
FROM members m
WHERE m.member_id NOT IN (
    SELECT DISTINCT member_id
    FROM borrow_records
    WHERE return_date IS NULL
);

-- 11. Count number of borrows per category in the last 90 days
SELECT c.category_name, COUNT(*) AS borrow_count
FROM borrow_records br
JOIN books b ON br.book_id = b.book_id
JOIN categories c ON b.category_id = c.category_id
WHERE br.borrow_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
GROUP BY c.category_name
ORDER BY borrow_count DESC;

-- 12.Calculate total fine amount for each member 
SELECT m.name, SUM(f.amount) AS total_fines
FROM fines f
JOIN borrow_records br ON f.borrow_id = br.borrow_id
JOIN members m ON br.member_id = m.member_id
GROUP BY m.name
ORDER BY total_fines DESC;

-- 13.find books that are borrowed more than the average borrow count

WITH borrow_stats AS (
    SELECT book_id, COUNT(*) AS borrow_count
    FROM borrow_records
    GROUP BY book_id
)
SELECT b.title, bs.borrow_count
FROM borrow_stats bs
JOIN books b ON bs.book_id = b.book_id
WHERE bs.borrow_count > (
    SELECT AVG(borrow_count) FROM borrow_stats
);

-- 14. find members with the latest borrow date
SELECT m.member_id, m.name, br.borrow_date
FROM borrow_records br
JOIN members m 
ON br.member_id = m.member_id
WHERE br.borrow_date = (
    SELECT MAX(borrow_date)
    FROM borrow_records
    WHERE member_id = m.member_id
);

-- 15. Monthly borrow trend (last 6 months)

SELECT DATE_FORMAT(borrow_date, '%Y-%m') AS month, COUNT(*) AS total_borrows
FROM borrow_records
WHERE borrow_date >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
GROUP BY month
ORDER BY month;

-- 16. Rank members based on total fines paid
SELECT m.name, SUM(f.amount) AS total_fines,
       RANK() OVER (ORDER BY SUM(f.amount) DESC) AS fine_rank
FROM fines f
JOIN borrow_records br
 ON f.borrow_id = br.borrow_id
JOIN members m ON br.member_id = m.member_id
GROUP BY m.name;

-- 17. Identify books that were borrowed and returned on the same day
SELECT b.title, m.name, br.borrow_date
FROM borrow_records br
JOIN books b ON br.book_id = b.book_id
JOIN members m ON br.member_id = m.member_id
WHERE br.return_date = br.borrow_date;

-- 18. Find the most popular borrowing day of the week

SELECT DAYNAME(borrow_date) AS day_of_week, COUNT(*) AS total_borrows
FROM borrow_records
GROUP BY day_of_week
ORDER BY total_borrows DESC
LIMIT 1;

-- 19. Find members who borrowed books in consecutive months
WITH borrow_months AS (
    SELECT member_id, YEAR(borrow_date) AS yr, MONTH(borrow_date) AS mn
    FROM borrow_records
    GROUP BY member_id, yr, mn
)
SELECT DISTINCT bm1.member_id
FROM borrow_months bm1
JOIN borrow_months bm2
  ON bm1.member_id = bm2.member_id
 AND (bm2.mn = bm1.mn + 1 OR (bm1.mn = 12 AND bm2.mn = 1 AND bm2.yr = bm1.yr + 1));
 

-- 20. Find the percentage of late returns for each category
SELECT c.category_name,
       ROUND(SUM(CASE WHEN return_date > due_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_percentage
FROM borrow_records br
JOIN books b ON br.book_id = b.book_id
JOIN categories c ON b.category_id = c.category_id
GROUP BY c.category_name;




