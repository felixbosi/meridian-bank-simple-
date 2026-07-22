-- Step 4: 
--Try these queries once your data is loaded

USE MeridianBank;


-- Quick check: row counts in every table
SELECT 'Branches' AS TableName, COUNT(*) AS RowCount FROM Branches
UNION ALL SELECT 'Customers', COUNT(*) FROM Customers
UNION ALL SELECT 'Accounts', COUNT(*) FROM Accounts
UNION ALL SELECT 'Transactions', COUNT(*) FROM Transactions
UNION ALL SELECT 'Cards', COUNT(*) FROM Cards
UNION ALL SELECT 'Loans', COUNT(*) FROM Loans
UNION ALL SELECT 'LoanPayments', COUNT(*) FROM LoanPayments;


-- Let us check for the toal balance held per branch.
-- Total balance held per branch will be;

SELECT
    b.BranchName,
    COUNT(a.AccountID) AS NumAccounts,
    SUM(a.CurrentBalance) AS TotalBalance
FROM Accounts a
JOIN Branches b ON b.BranchID = a.BranchID
WHERE a.Status = 'active'
GROUP BY b.BranchName
ORDER BY TotalBalance DESC;


-- Let us get the default rate by credit score band.
-- Loan default rate by credit score band will be

SELECT
    CASE
        WHEN c.CreditScore < 580 THEN 'Poor (<580)'
        WHEN c.CreditScore < 660 THEN 'Fair (580-659)'
        WHEN c.CreditScore < 740 THEN 'Good (660-739)'
        ELSE 'Excellent (740+)'
    END AS CreditBand,
    COUNT(*) AS TotalLoans,
    SUM(CASE WHEN l.Status = 'defaulted' THEN 1 ELSE 0 END) AS Defaults
FROM Loans l
JOIN Customers c ON c.CustomerID = l.CustomerID
GROUP BY CASE
        WHEN c.CreditScore < 580 THEN 'Poor (<580)'
        WHEN c.CreditScore < 660 THEN 'Fair (580-659)'
        WHEN c.CreditScore < 740 THEN 'Good (660-739)'
        ELSE 'Excellent (740+)'
    END
ORDER BY Defaults DESC;


-- Let us try to flag any fraudulent transactions.
-- Flagged fraud transactions

SELECT TransactionID, AccountID, TransactionDate, Amount, Channel, MerchantCategory
FROM Transactions
WHERE IsFlaggedFraud = 1
ORDER BY Amount DESC;


--let us perform a window function.
-- Window function example: rank customers by total account balance

SELECT
    a.CustomerID,
    SUM(a.CurrentBalance) AS TotalBalance,
    RANK() OVER (ORDER BY SUM(a.CurrentBalance) DESC) AS BalanceRank
FROM Accounts a
WHERE a.Status = 'active'
GROUP BY a.CustomerID
ORDER BY BalanceRank;
