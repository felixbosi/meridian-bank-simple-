-- Use this INSTEAD of reloading everything, if you already have data
-- loaded with 2-letter state codes (NY, CA, etc.) and just want to
-- convert those to full state names in place.

USE MeridianBank;
GO

UPDATE Branches SET State = 'New York' WHERE State = 'NY';
UPDATE Branches SET State = 'California' WHERE State = 'CA';
UPDATE Branches SET State = 'Texas' WHERE State = 'TX';
UPDATE Branches SET State = 'Illinois' WHERE State = 'IL';
UPDATE Branches SET State = 'Florida' WHERE State = 'FL';
UPDATE Branches SET State = 'Ohio' WHERE State = 'OH';
UPDATE Branches SET State = 'Washington' WHERE State = 'WA';
UPDATE Branches SET State = 'Georgia' WHERE State = 'GA';
GO

UPDATE Customers SET State = 'New York' WHERE State = 'NY';
UPDATE Customers SET State = 'California' WHERE State = 'CA';
UPDATE Customers SET State = 'Texas' WHERE State = 'TX';
UPDATE Customers SET State = 'Illinois' WHERE State = 'IL';
UPDATE Customers SET State = 'Florida' WHERE State = 'FL';
UPDATE Customers SET State = 'Ohio' WHERE State = 'OH';
UPDATE Customers SET State = 'Washington' WHERE State = 'WA';
UPDATE Customers SET State = 'Georgia' WHERE State = 'GA';
GO

-- Note: if your State columns are still NVARCHAR(2) from the original
-- schema, run this first or the UPDATEs above will fail/truncate:
-- ALTER TABLE Branches ALTER COLUMN State NVARCHAR(20);
-- ALTER TABLE Customers ALTER COLUMN State NVARCHAR(20);

-- Confirm the change
SELECT DISTINCT State FROM Branches;
SELECT DISTINCT State FROM Customers;
