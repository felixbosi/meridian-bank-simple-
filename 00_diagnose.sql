-- Run this to see exactly what's currently in your database.
-- This tells us precisely which tables loaded and which didn't.

USE MeridianBank;
GO

SELECT 'Branches' AS TableName, COUNT(*) AS RowCount FROM Branches
UNION ALL SELECT 'Customers', COUNT(*) FROM Customers
UNION ALL SELECT 'Accounts', COUNT(*) FROM Accounts
UNION ALL SELECT 'Cards', COUNT(*) FROM Cards
UNION ALL SELECT 'Loans', COUNT(*) FROM Loans
UNION ALL SELECT 'LoanPayments', COUNT(*) FROM LoanPayments
UNION ALL SELECT 'Transactions', COUNT(*) FROM Transactions;
