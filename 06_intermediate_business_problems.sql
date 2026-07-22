

USE MeridianBank;


-- Q1: Loan default rate by credit score band (CASE-based bucketing)
SELECT
    CASE
        WHEN c.CreditScore < 580 THEN 'Poor (<580)'
        WHEN c.CreditScore < 660 THEN 'Fair (580-659)'
        WHEN c.CreditScore < 740 THEN 'Good (660-739)'
        ELSE 'Excellent (740+)'
    END AS CreditBand,
    COUNT(*) AS TotalLoans,
    SUM(CASE WHEN l.Status = 'defaulted' THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0 * SUM(CASE WHEN l.Status = 'defaulted' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS DefaultRatePct
FROM Loans l
JOIN Customers c ON c.CustomerID = l.CustomerID
GROUP BY CASE
        WHEN c.CreditScore < 580 THEN 'Poor (<580)'
        WHEN c.CreditScore < 660 THEN 'Fair (580-659)'
        WHEN c.CreditScore < 740 THEN 'Good (660-739)'
        ELSE 'Excellent (740+)'
    END
ORDER BY DefaultRatePct DESC;



-- Q2: Customers whose average transaction amount exceeds their branch's average
-- (correlated subquery -- classic interview pattern)
SELECT
    c.CustomerID,
    a.BranchID,
    AVG(t.Amount) AS CustomerAvgTxn
FROM Transactions t
JOIN Accounts a ON a.AccountID = t.AccountID
JOIN Customers c ON c.CustomerID = a.CustomerID
GROUP BY c.CustomerID, a.BranchID
HAVING AVG(t.Amount) > (
    SELECT AVG(t2.Amount)
    FROM Transactions t2
    JOIN Accounts a2 ON a2.AccountID = t2.AccountID
    WHERE a2.BranchID = a.BranchID
);



-- Q3: Fraud rate by channel, with a subquery for the overall baseline rate for comparison
SELECT
    Channel,
    COUNT(*) AS TotalTxns,
    SUM(CAST(IsFlaggedFraud AS INT)) AS FraudCount,
    CAST(100.0 * SUM(CAST(IsFlaggedFraud AS INT)) / COUNT(*) AS DECIMAL(6,3)) AS FraudRatePct,
    (SELECT CAST(100.0 * SUM(CAST(IsFlaggedFraud AS INT)) / COUNT(*) AS DECIMAL(6,3))
     FROM Transactions) AS OverallFraudRatePct
FROM Transactions
GROUP BY Channel
ORDER BY FraudRatePct DESC;



-- Q4: Loans with 2+ missed payments in the trailing 6 months (delinquency early-warning)
SELECT
    lp.LoanID,
    l.CustomerID,
    l.LoanType,
    l.Status,
    COUNT(*) AS MissedPaymentsLast6Mo
FROM LoanPayments lp
JOIN Loans l ON l.LoanID = lp.LoanID
WHERE lp.PaymentStatus = 'missed'
  AND lp.PaymentDate >= DATEADD(MONTH, -6, '2026-07-01')
GROUP BY lp.LoanID, l.CustomerID, l.LoanType, l.Status
HAVING COUNT(*) >= 2
ORDER BY MissedPaymentsLast6Mo DESC;



-- Q5: Percentage of customers holding both a loan and an active account
-- (cross-sell measurement, common banking KPI)
SELECT
    CAST(100.0 * COUNT(DISTINCT l.CustomerID) / (SELECT COUNT(*) FROM Customers) AS DECIMAL(5,2))
        AS PctCustomersWithLoanAndAccount
FROM Loans l
WHERE l.CustomerID IN (SELECT CustomerID FROM Accounts WHERE Status = 'active');



-- Q6: Dormant accounts (no transactions in the trailing 12 months) with current balance > $0
SELECT
    a.AccountID,
    a.CustomerID,
    a.AccountType,
    a.CurrentBalance
FROM Accounts a
WHERE a.Status IN ('active', 'dormant')
  AND a.CurrentBalance > 0
  AND NOT EXISTS (
      SELECT 1 FROM Transactions t
      WHERE t.AccountID = a.AccountID
        AND t.TransactionDate >= DATEADD(MONTH, -12, '2026-07-01')
  )
ORDER BY a.CurrentBalance DESC;

