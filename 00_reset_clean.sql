-- Run this to wipe out any partial data and start completely clean.
-- Deletes in child-to-parent order so no FK errors occur during cleanup.
-- Does NOT drop the tables themselves -- just empties them.

USE MeridianBank;


DELETE FROM Transactions;
DELETE FROM LoanPayments;
DELETE FROM Cards;
DELETE FROM Loans;
DELETE FROM Accounts;
DELETE FROM Customers;
DELETE FROM Branches;


-- Reset the IDENTITY counters back to 0 so new rows start at ID 1 again
DBCC CHECKIDENT ('Branches', RESEED, 0);
DBCC CHECKIDENT ('Customers', RESEED, 0);
DBCC CHECKIDENT ('Accounts', RESEED, 0);
DBCC CHECKIDENT ('Cards', RESEED, 0);
DBCC CHECKIDENT ('Loans', RESEED, 0);
DBCC CHECKIDENT ('LoanPayments', RESEED, 0);
DBCC CHECKIDENT ('Transactions', RESEED, 0);


-- Confirm everything is now empty
SELECT 'Branches' AS TableName, COUNT(*) AS RowCount FROM Branches
UNION ALL SELECT 'Customers', COUNT(*) FROM Customers
UNION ALL SELECT 'Accounts', COUNT(*) FROM Accounts
UNION ALL SELECT 'Cards', COUNT(*) FROM Cards
UNION ALL SELECT 'Loans', COUNT(*) FROM Loans
UNION ALL SELECT 'LoanPayments', COUNT(*) FROM LoanPayments
UNION ALL SELECT 'Transactions', COUNT(*) FROM Transactions;

-- All 7 should show 0. Once confirmed, open 03_insert_sample_data.sql,
-- click anywhere in the editor, press Ctrl+A to select the ENTIRE file
-- (this is the important part -- not just scrolling to the top), then
-- click Execute. That guarantees Branches and Customers load first.
