--Meridian Bank Risk Intelligence & Performance Analytics :
--Designed and built a full-stack banking analytics pipeline on a simulated retail bank dataset, translating business questions into production-style SQL
--used for credit risk, fraud detection, and customer intelligence.

Highlights:
  
--Engineered a normalized relational schema (7 tables) modeling core banking operations: accounts, transactions, loans, cards, and branches.
--Built credit risk segmentation and loan cohort analysis to detect underwriting drift and quantify default rates by risk band.
--Developed real-time-style fraud anomaly detection using per-account trailing-average heuristics and channel-level fraud-rate bench-marking — not static thresholds.
--Implemented RFM customer segmentation (Recency, Frequency, Monetary) for retention and cross-sell targeting.
--Built early-warning delinquency scoring and dormant high-value account identification to surface risk and revenue opportunities before they hit official reporting.
--Delivered branch-level performance ranking and monthly cash-flow trend analysis using advanced window functions.

-- This will be our database.
  
USE MeridianBank;


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
