-- ============================================================
-- Step 5: Advanced Business Problems
-- ============================================================
-- These go beyond basic joins/aggregation into the kind of analysis
-- a real risk, fraud, or customer analytics team would actually ask
-- for. Each one is framed as a business question first, with the
-- reasoning behind the approach.

USE MeridianBank;


-- ============================================================
-- 1. LOAN PERFORMANCE COHORTS
-- Business question: "Are loans we originate now riskier than loans
-- we originated a year ago?" This is the lending-sector equivalent of
-- a subscription business's churn cohort analysis, and it's exactly
-- how a credit risk team monitors whether underwriting standards are
-- drifting over time.
-- Let us answer this question;


WITH LoanCohorts AS (
    SELECT
        LoanID,
        Status,
        OriginationDate,
        DATEFROMPARTS(YEAR(OriginationDate), (DATEPART(QUARTER, OriginationDate) - 1) * 3 + 1, 1) AS CohortQuarter
    FROM Loans
)
SELECT
    CohortQuarter,
    COUNT(*) AS TotalLoans,
    SUM(CASE WHEN Status = 'defaulted' THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0 * SUM(CASE WHEN Status = 'defaulted' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS DefaultRatePct
FROM LoanCohorts
GROUP BY CohortQuarter
ORDER BY CohortQuarter;



-- ============================================================
-- 2. BRANCH RISK RANKING
-- Business question: "Which branches are originating the riskiest
-- loans?" Only branches with 5+ loans are included so a single bad
-- loan at a small branch doesn't distort the ranking -- as a real
-- analyst, i chose to apply exactly this kind of minimum-sample-size filter.
-- ============================================================

WITH BranchDefaults AS (
    SELECT
        b.BranchID,
        b.BranchName,
        COUNT(*) AS TotalLoans,
        SUM(CASE WHEN l.Status = 'defaulted' THEN 1 ELSE 0 END) AS Defaults
    FROM Loans l
    JOIN Branches b ON b.BranchID = l.BranchID
    GROUP BY b.BranchID, b.BranchName
    HAVING COUNT(*) >= 5
)
SELECT
    BranchName,
    TotalLoans,
    Defaults,
    CAST(100.0 * Defaults / TotalLoans AS DECIMAL(5,1)) AS DefaultRatePct,
    RANK() OVER (ORDER BY CAST(Defaults AS FLOAT) / TotalLoans DESC) AS RiskRank
FROM BranchDefaults
ORDER BY RiskRank;



-- ============================================================
-- 3. FRAUD ANOMALY DETECTION
-- Business question: "Flag any transaction that looks unusual for
-- THIS SPECIFIC account" -- not unusual in general, since a $2,000
-- transaction is normal for one customer and alarming for another.
--- NB:
-- This compares each transaction to that account's own trailing
-- 30-transaction average, which is a real heuristic fraud teams use
-- as a first-pass filter before human review.
-- ============================================================
WITH TxnWithAvg AS (
    SELECT
        TransactionID,
        AccountID,
        TransactionDate,
        Amount,
        Channel,
        IsFlaggedFraud,
        AVG(Amount) OVER (
            PARTITION BY AccountID
            ORDER BY TransactionDate
            ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING
        ) AS TrailingAvgAmount
    FROM Transactions
    WHERE TransactionType IN ('purchase', 'withdrawal')
)
SELECT
    TransactionID,
    AccountID,
    TransactionDate,
    Amount,
    TrailingAvgAmount,
    Channel,
    IsFlaggedFraud
FROM TxnWithAvg
WHERE TrailingAvgAmount IS NOT NULL
  AND Amount > 3 * TrailingAvgAmount
  AND Amount > 200   -- ignore trivially small trailing averages
ORDER BY Amount DESC;



-- ============================================================
-- 4. CUSTOMER VALUE SEGMENTATION (RFM)
-- Business question: "Which customers should retention/marketing
-- prioritize?" RFM (Recency, Frequency, Monetary) is a standard
-- customer-value framework used across banking, retail, and
-- subscription businesses.
-- ============================================================
WITH CustomerActivity AS (
    SELECT
        a.CustomerID,
        DATEDIFF(DAY, MAX(t.TransactionDate), '2026-07-01') AS RecencyDays,
        COUNT(t.TransactionID) AS Frequency
    FROM Accounts a
    JOIN Transactions t ON t.AccountID = a.AccountID
    GROUP BY a.CustomerID
),
CustomerBalance AS (
    SELECT CustomerID, SUM(CurrentBalance) AS TotalBalance
    FROM Accounts
    WHERE Status = 'active'
    GROUP BY CustomerID
),
RfmScores AS (
    SELECT
        s.CustomerID,
        s.RecencyDays,
        s.Frequency,
        ISNULL(b.TotalBalance, 0) AS TotalBalance,
        NTILE(5) OVER (ORDER BY s.RecencyDays DESC) AS RScore,
        NTILE(5) OVER (ORDER BY s.Frequency ASC) AS FScore,
        NTILE(5) OVER (ORDER BY ISNULL(b.TotalBalance, 0) ASC) AS MScore
    FROM CustomerActivity s
    LEFT JOIN CustomerBalance b ON b.CustomerID = s.CustomerID
)
SELECT
    CustomerID,
    RecencyDays,
    Frequency,
    TotalBalance,
    RScore, FScore, MScore,
    (RScore + FScore + MScore) AS RfmTotal,
    CASE
        WHEN (RScore + FScore + MScore) >= 13 THEN 'Premium'
        WHEN (RScore + FScore + MScore) >= 10 THEN 'Core'
        WHEN (RScore + FScore + MScore) >= 7  THEN 'At Risk'
        ELSE 'Inactive'
    END AS Segment
FROM RfmScores
ORDER BY RfmTotal DESC;



-- ============================================================
-- 5. RUNNING MONTHLY NET CASH FLOW
-- Business question: "Is the bank's deposit base growing or shrinking
-- month over month?" A cumulative running total plus a month-over-
-- month comparison is exactly what a finance/treasury team tracks --
-- this demonstrates SUM() OVER and LAG() together, two of the most
-- commonly tested window functions.
-- ============================================================

WITH MonthlyFlow AS (
    SELECT
        DATEFROMPARTS(YEAR(TransactionDate), MONTH(TransactionDate), 1) AS TxnMonth,
        SUM(CASE WHEN TransactionType = 'deposit' THEN Amount ELSE 0 END)
          - SUM(CASE WHEN TransactionType = 'withdrawal' THEN Amount ELSE 0 END) AS NetFlow
    FROM Transactions
    GROUP BY DATEFROMPARTS(YEAR(TransactionDate), MONTH(TransactionDate), 1)
)
SELECT
    TxnMonth,
    NetFlow,
    SUM(NetFlow) OVER (ORDER BY TxnMonth ROWS UNBOUNDED PRECEDING) AS CumulativeNetFlow,
    LAG(NetFlow) OVER (ORDER BY TxnMonth) AS PriorMonthNetFlow
FROM MonthlyFlow
ORDER BY TxnMonth;



-- ============================================================
-- 6. CROSS-SELL OPPORTUNITY IDENTIFICATION
-- Business question: "Which active customers have never been offered
-- a loan product?
--n NB:
--This is a real revenue-growth query -- banks make
-- meaningful revenue from cross-selling existing customers rather
-- than acquiring new ones, so surfacing this list is directly
-- actionable for a sales/relationship-banking team.
-- ============================================================
SELECT
    c.CustomerID,
    c.CreditScore,
    c.EmploymentStatus,
    SUM(a.CurrentBalance) AS TotalBalance
FROM Customers c
JOIN Accounts a ON a.CustomerID = c.CustomerID AND a.Status = 'active'
WHERE c.CreditScore >= 660   -- reasonable underwriting floor
  AND NOT EXISTS (
      SELECT 1 FROM Loans l WHERE l.CustomerID = c.CustomerID
  )
GROUP BY c.CustomerID, c.CreditScore, c.EmploymentStatus
HAVING SUM(a.CurrentBalance) > 5000   -- meaningful existing relationship
ORDER BY TotalBalance DESC;



-- ============================================================
-- 7. LOAN PAYMENT CONSISTENCY SCORE
-- Business question: "Which currently-active loans are trending
-- toward delinquency before they officially become delinquent?" A
-- running on-time-payment percentage is an early-warning signal --
-- catching risk before it shows up in the official status field is
-- exactly the kind of proactive analysis that separates a strong
-- analyst from someone who only reports what already happened.
-- ============================================================

WITH PaymentFlags AS (
    SELECT
        LoanID,
        PaymentDate,
        PaymentStatus,
        CASE WHEN PaymentStatus = 'on_time' THEN 1 ELSE 0 END AS OnTimeFlag,
        ROW_NUMBER() OVER (PARTITION BY LoanID ORDER BY PaymentDate) AS PaymentSeq
    FROM LoanPayments
)
SELECT
    pf.LoanID,
    l.Status AS CurrentLoanStatus,
    pf.PaymentDate,
    pf.PaymentSeq,
    pf.PaymentStatus,
    CAST(100.0 * AVG(pf.OnTimeFlag) OVER (
        PARTITION BY pf.LoanID ORDER BY pf.PaymentDate
        ROWS UNBOUNDED PRECEDING
    ) AS DECIMAL(5,1)) AS RunningOnTimePct
FROM PaymentFlags pf
JOIN Loans l ON l.LoanID = pf.LoanID
WHERE l.Status = 'active'   -- focus on loans not yet flagged delinquent/defaulted
ORDER BY pf.LoanID, pf.PaymentSeq;



-- ============================================================
-- 8. DORMANT HIGH-VALUE ACCOUNTS (RE-ENGAGEMENT TARGETS)
-- Business question: "Which dormant accounts are worth a
-- re-engagement campaign? 
-- Giving that " A dormant account sitting at $50 isn't
-- worth outreach; one sitting at $15,000 is a real retention
-- opportunity slipping away. This ranks dormant accounts by balance
-- so a marketing team can prioritize outreach by expected value.
-- ============================================================

SELECT
    a.AccountID,
    a.CustomerID,
    a.AccountType,
    a.CurrentBalance,
    a.OpenDate,
    RANK() OVER (ORDER BY a.CurrentBalance DESC) AS ValueRank
FROM Accounts a
WHERE a.Status = 'dormant'
ORDER BY a.CurrentBalance DESC;

