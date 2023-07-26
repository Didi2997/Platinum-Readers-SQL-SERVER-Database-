/* PLATINUM READERS IS A CHAIN OF BOOKSTORES WITH BRANCHES IN SEVEN STATES IN THE USA NAMELY: 
ARIZONA, WASHINGTON, NEW JERSEY, CALIFORNIA, ARKANSAS, TEXAS, AND NEW YORK.
THEY HAVE ASKED US TO CREATE A SQL DATABASE CONTAINING RECORDS OF CUSTOMER INFORMATION AND BOOKS SALES
FROM JULY 2022 THROUGH DECEMBER 2022, AFTER WHICH WE WILL QUERY THIS DATASET TO CONDUCT SOME DATA EXPLORATION
TO ANSWER SOME IMPORTANT ANALYTICAL QUESTIONS REGARDING THE BUSINESS PERFORMANCE OF THE 'PLATINUM READERS' BOOKSTORE CHAIN */


-- WE START BY CREATING THE DATABASE WHICH WILL HOUSE OUR BOOK SALES RECORDS
--CREATE DATABASE PlatinumReaders
--USE PlatinumReaders

--CREATE THE 'BOOK', 'CUSTOMER', 'SALES', AND 'AUTHOR' TABLES RESPECTIVELY:

/* (1) CREATE THE 'BOOK' TABLE
	EACH BOOK WILL HAVE AN ID THAT GOES IN THIS FORMAT => "PBK-00#". SO WE WILL
	CREATE A SEQUENCE WHICH WE WILL ATTACH TO THE ABOVE CUSTOM ID 
	TO AUTO-INCREMENT EACH BOOK ID, CONCATENATING THE INCREMENT WITH THE CUSTOM ID: 
GO
CREATE SEQUENCE ID AS INT
	START WITH 1
	INCREMENT BY 1
	NO CACHE
GO
-- THEN WRITE THE QUERY FOR CREATING THE 'BOOK'
CREATE TABLE Book
(ID NVARCHAR(25) NOT NULL 
	CONSTRAINT DF_Book_ID DEFAULT FORMAT((NEXT VALUE FOR ID), 'PBK-000')
	CONSTRAINT PK_Book_ID PRIMARY KEY(ID),
Title NVARCHAR(50) NOT NULL,
Genre NVARCHAR(25) NOT NULL,
Edition NVARCHAR(20),
NumberOfPages SMALLINT)


--(2) CREATE THE 'CUSTOMER' TABLE IN THE SAME WAY WE CREATED THE 'BOOK' TABLE USING A CREATED SEQUENCE
-- (THIS TIME, THE CUSTOM ID FORMAT FOR EACH CUSTOMER WILL BE => "PKC-00#")
GO
	CREATE SEQUENCE CustomerID AS INT
	START WITH 1
	INCREMENT BY 1
	NO CACHE 
GO
CREATE TABLE Customer
(CustomerID NVARCHAR(25) NOT NULL
	CONSTRAINT DF_Customer_CustomerID DEFAULT FORMAT((NEXT VALUE FOR CustomerID),'PKC-000')
	CONSTRAINT PK_Customer_CustomerID PRIMARY KEY(CustomerID),
Name NVARCHAR(50) NOT NULL,
Age SMALLINT NOT NULL,
Gender NVARCHAR(10) NOT NULL
	CONSTRAINT CK_Customer_Gender CHECK((Gender) IN ('Male', 'Female')),
Location NVARCHAR(25) NOT NULL
	CONSTRAINT CK_Customer_Location CHECK((Location) IN 
	('Arizona', 'Washington', 'New Jersey', 'California', 'Texas', 'Arkansas', 'New York')))


--(3) CREATE THE 'BOOKSALES' TABLE
CREATE TABLE BookSales
(SaleID INT NOT NULL
	CONSTRAINT PK_BookSales_ID PRIMARY KEY(SaleID) IDENTITY(1000,1),
CustomerID NVARCHAR(25) NOT NULL
	CONSTRAINT FK_BookSales_CustomerID FOREIGN KEY(CustomerID) REFERENCES Customer(CustomerID),
Book_ID NVARCHAR(25) NOT NULL
	CONSTRAINT FK_BookSales_Book_ID FOREIGN KEY(Book_ID) REFERENCES Book(ID),
Quantity SMALLINT NOT NULL,
Price DECIMAL(5,2) NOT NULL,
DateOfSale DATE NOT NULL)


--(4) CREATE THE 'AUTHOR' TABLE
CREATE TABLE Author
(RowID SMALLINT NOT NULL 
	CONSTRAINT PK_Author_RowID PRIMARY KEY(RowID) IDENTITY(1,1),
AuthorID NVARCHAR(25) NOT NULL,
Name NVARCHAR(25) NOT NULL,
BookID NVARCHAR(25) NOT NULL
	CONSTRAINT FK_Author_BookID FOREIGN KEY(BookID) REFERENCES Book(ID)
	CONSTRAINT UQ_Author_BookID UNIQUE(BookID)) */

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

-- WHAT ARE THE ID AND TITLE OF THE BOOK WITH THE LARGEST QUANTITY OF ORDERS?
SELECT TOP 1 bs.Book_ID, b.Title, SUM(Quantity) AS TotalQuantityOrders
FROM Book b
JOIN BookSales bs
ON b.ID = bs.Book_ID
GROUP BY bs.Book_ID, b.Title
ORDER BY TotalQuantityOrders DESC


-- WHAT IS THE LOCATION WITH THE HIGHEST REVENUE?
SELECT TOP 1 cr.Location, SUM(bs.Quantity * bs.Price) AS Revenue
FROM Customer AS cr,
	 BookSales AS bs
WHERE cr.CustomerID = bs.CustomerID
GROUP BY cr.Location
ORDER BY Revenue DESC


-- DISPLAY ID, TITLE, AND GENRE OF BOOKS THAT HAVE BEEN ORDERED BY AT LEAST 10 DIFFERENT CUSTOMERS
SELECT TopBooks.Book_ID, Bk.Title, Bk.Genre
FROM 
	(SELECT DISTINCT Book_ID
	FROM (SELECT Book_ID, CustomerID, DENSE_RANK() OVER 
	(PARTITION BY Book_ID ORDER BY CustomerID) AS BookRank
	FROM BookSales) AS r
	GROUP BY Book_ID, BookRank
	HAVING BookRank >= 10) AS TopBooks
JOIN Book AS Bk
ON TopBooks.Book_ID = Bk.ID


--WHAT MONTH OF THE YEAR WERE SALES AT THEIR PEAK AND AT THEIR LOWEST?
WITH PeakSales AS (SELECT MONTH(DateofSale) AS MonthID, DATENAME(MONTH, DateOfSale) AS MonthName, 
SUM(Price * Quantity) AS Revenue
FROM BookSales
GROUP BY MONTH(DateOfSale), DATENAME(MONTH, DateOfSale))
SELECT *
FROM PeakSales 
WHERE Revenue = (SELECT MAX(Revenue) FROM PeakSales)
UNION
SELECT *
FROM PeakSales
WHERE Revenue = (SELECT MIN(Revenue) FROM PeakSales)


--RUNNING TOTAL REVENUE FOR SALES FROM JULY TO DECEMBER
SELECT Book_ID, CustomerID, DateOfSale, (Price * Quantity) AS Revenue,
	SUM(Price * Quantity) OVER (ORDER BY DateOfSale 
	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RollingRevenueTotal
FROM BookSales


--WHAT GENRE SOLD THE MOST?
WITH CTE_GenreSale AS
(SELECT bk.Genre, SUM(bks.Price * bks.Quantity) AS Revenue
FROM Book AS bk
JOIN BookSales AS bks
ON bk.ID = bks.Book_ID
GROUP BY bk.Genre)
SELECT TOP 1 Genre, Revenue
FROM CTE_GenreSale
GROUP BY Genre, Revenue
ORDER BY Revenue DESC


--ADD A 'REVENUE' COLUMN IN THE 'BOOKSALES' TABLE IN WHICH THE PRICE AND QUANTITY ARE MULTIPLIED TOGETHER
ALTER TABLE BookSales
ADD Revenue DECIMAL(5,2)  
UPDATE BookSales
SET Revenue = Price * Quantity


--SALES TOTAL PER GENDER
SELECT 'Male' AS Gender, SUM(bs.Revenue) AS TotalSales
	FROM Customer AS c
	JOIN BookSales AS bs
	ON c.CustomerID = bs.CustomerID
	WHERE Gender = 'Male'
UNION
SELECT 'Female', SUM(bs.Revenue)
	FROM Customer AS c
	JOIN BookSales AS bs
	ON c.CustomerID = bs.CustomerID
	WHERE Gender = 'Female'


--SHOW TOTAL AVERAGE OF ORDERS BASED ON AGE DEMOGRAPHIC
SELECT AVG(s.QuantityOfOrders) AS TotalAverageOfOrderQuantity, s.AgeRange FROM (SELECT *, 
CASE 
	WHEN R.Age BETWEEN 21 AND 30 THEN '21-30'
	WHEN R.Age BETWEEN 31 AND 40 THEN '31-40'
	WHEN R.Age BETWEEN 41 AND 50 THEN '41-50'
	WHEN R.Age BETWEEN 51 AND 60 THEN '51-60'
	WHEN R.Age BETWEEN 61 AND 70 THEN '61-70'
	WHEN R.Age BETWEEN 71 AND 80 THEN '71-80'
	ELSE NULL
END AS AgeRange
FROM (SELECT c.CustomerID, c.name, c.age, SUM(b.Quantity) AS QuantityOfOrders
FROM Customer AS c
JOIN BookSales AS b
ON c.CustomerID = b.CustomerID
GROUP BY c.CustomerID, c.name, c.age) AS R) AS S
GROUP BY AgeRange


--WHICH BOOK(S) WAS NOT BOUGHT DURING THE TIME PERIOD IN REVIEW?
SELECT b.ID, b.Title
FROM BookSales AS bs
RIGHT JOIN Book AS b
ON bs.Book_ID = b.ID
WHERE bs.Book_ID IS NULL


--DISPLAY FULL INFO OF CUSTOMERS WHO DID NOT PURCHASE ANY BOOK WITHIN THE TIME PERIOD IN REVIEW
SELECT CustomerID, Name, Age, Gender, [Location]
FROM Customer
EXCEPT
SELECT b.CustomerID, c.Name, c.Age, c.Gender, c.[Location]
FROM BookSales b
FULL OUTER JOIN Customer c
ON b.CustomerID = c.CustomerID


--DISPLAY TOP 10 PATRONS
SELECT TOP 10 b.CustomerID, c.Name, c.Age, c.Gender, c.Location, SUM(b.Revenue) AS TotalSales
FROM Customer AS c
LEFT JOIN BookSales AS b
ON c.CustomerID = b.CustomerID
GROUP BY b.CustomerID, c.Name, c.Age, c.Gender, c.Location
ORDER BY SUM(b.Revenue) DESC


--BEST SELLING AUTHOR
WITH CTE_BestAuthor AS 
	(SELECT a.AuthorID, a.Name, SUM(b.Revenue) AS SumRev
	FROM Author AS a
	JOIN BookSales AS b
	ON a.BookID = b.Book_ID
	GROUP BY a.AuthorID, a.Name)
SELECT *
FROM CTE_BestAuthor 
WHERE SumRev = (SELECT MAX(SumRev) FROM CTE_BestAuthor)


--AVERAGE TOTAL SALE PER MONTH
SELECT MONTH(DateOfSale) AS MonthID, 
DATENAME(MONTH, DateOfSale) AS MonthName, AVG(Revenue) AS MonthlyAverage
FROM BookSales
GROUP BY MONTH(DateOfSale), DATENAME(MONTH, DateOfSale)
ORDER BY MONTH(DateOfSale)


--EXTRACT THE BEST SELLING BOOK PER MONTH ALONG WITH THE BOOK_ID, TITLE AND NAME OF AUTHOR
WITH CTE_MonthyBestSeller AS
(SELECT MONTH(DateOfSale) AS MonthID, DATENAME(MONTH, DateOfSale) AS MonthName, 
bs.book_ID, b.title, a.name AS AuthorName, SUM(bs.Revenue) AS TotalRev, 
ROW_NUMBER() OVER(PARTITION BY MONTH(DateOfSale) ORDER BY SUM(Revenue) DESC) AS TotalRevRank
	FROM BookSales AS bs
	JOIN Book AS b
	ON bs.Book_ID = b.ID
	JOIN Author AS a
	ON b.ID = a.BookID
	GROUP BY MONTH(bs.DateOfSale), DATENAME(MONTH, bs.DateOfSale), bs.Book_ID, b.Title, a.name)
SELECT MonthName, Book_ID, Title, AuthorName, TotalRev
FROM CTE_MonthyBestSeller
WHERE TotalRevRank = 1
GROUP BY MonthID, MonthName, Book_ID, Title, AuthorName, TotalRev
ORDER BY MonthID


/* THE BUSINESS SEEKS TO CREATE A LIST WHICH WILL DISPLAY A REWARD SYSTEM FOR ITS CUSTOMERS BASED OFF OF 
THE AMOUNT OF REVENUE THEY'VE EACH GENERATED FOR THE BUSINESS WITHIN THE TIME FRAME IN REVIEW:
CUSTOMERS WITH REVENUE OF $250 AND ABOVE GET A 12% DISCOUNT ON THEIR NEXT PURCHASE
CUSTOMERS WITH REVENUE WORTH MORE THAN $149 OR LESS THAN $250 GET A 8% DISCOUNT ON THEIR NEXT PURCHASE
CUSTOMERS WITH REVENUE WORTH LESS THAN $150 GET 0 DISCOUNT. WE WILL STORE THIS INFO IN A TEMP TABLE */

DROP TABLE IF EXISTS #TopCustomers 
CREATE TABLE #TopCustomers 
(CustomerID NVARCHAR(25) NOT NULL,
CustomerName NVARCHAR(50) NOT NULL,
TotalRevenue DECIMAL(5,2))
INSERT INTO #TopCustomers
SELECT b.CustomerID, c.Name, SUM(b.Revenue) as Rev
	FROM BookSales b
	JOIN Customer c
	ON b.CustomerID = c.CustomerID
	GROUP BY b.CustomerID, c.Name
	ORDER BY Rev DESC
SELECT *,
CASE	
	WHEN TotalRevenue >= 250 THEN FORMAT(.12, 'P0')
	WHEN TotalRevenue > 149 AND TotalRevenue < 250 THEN FORMAT(.08, 'P0')
	ELSE NULL
END AS Discount
FROM #TopCustomers
ORDER BY 3 DESC, 4 DESC