--Let us  convert the state acronyms  to full state names .

USE MeridianBank;


UPDATE Branches SET State = 'New York' WHERE State = 'NY';
UPDATE Branches SET State = 'California' WHERE State = 'CA';
UPDATE Branches SET State = 'Texas' WHERE State = 'TX';
UPDATE Branches SET State = 'Illinois' WHERE State = 'IL';
UPDATE Branches SET State = 'Florida' WHERE State = 'FL';
UPDATE Branches SET State = 'Ohio' WHERE State = 'OH';
UPDATE Branches SET State = 'Washington' WHERE State = 'WA';
UPDATE Branches SET State = 'Georgia' WHERE State = 'GA';


UPDATE Customers SET State = 'New York' WHERE State = 'NY';
UPDATE Customers SET State = 'California' WHERE State = 'CA';
UPDATE Customers SET State = 'Texas' WHERE State = 'TX';
UPDATE Customers SET State = 'Illinois' WHERE State = 'IL';
UPDATE Customers SET State = 'Florida' WHERE State = 'FL';
UPDATE Customers SET State = 'Ohio' WHERE State = 'OH';
UPDATE Customers SET State = 'Washington' WHERE State = 'WA';
UPDATE Customers SET State = 'Georgia' WHERE State = 'GA';


-- ALTER TABLE Branches ALTER COLUMN State NVARCHAR(20);
-- ALTER TABLE Customers ALTER COLUMN State NVARCHAR(20);

-- Confirm the change
SELECT DISTINCT State FROM Branches;
SELECT DISTINCT State FROM Customers;
