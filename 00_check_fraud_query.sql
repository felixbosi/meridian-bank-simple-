USE MeridianBank;
GO

-- 1. Confirm Transactions actually loaded (should be 25,158)
SELECT COUNT(*) AS TotalTransactions FROM Transactions;

-- 2. Check how the fraud flag values actually look (in case it's a
--    type/format issue rather than a missing-data issue)
SELECT IsFlaggedFraud, COUNT(*) AS Count
FROM Transactions
GROUP BY IsFlaggedFraud;

-- 3. The original query
SELECT TransactionID, AccountID, TransactionDate, Amount, Channel, MerchantCategory
FROM Transactions
WHERE IsFlaggedFraud = 1
ORDER BY Amount DESC;
