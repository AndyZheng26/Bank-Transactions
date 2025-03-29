--				[ CLEANING ]

-- 1. [ Potential Irrelevant data ]
SELECT * 
FROM information_schema.columns
WHERE table_name = 'transactions_data_cleaned';

SELECT * 
FROM transactions_data_cleaned
LIMIT 20;

-- 2. [ Duplicate data ]

WITH DuplicatesCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY client_id, card_id, date, amount, merchant_id, use_chip, merchant_city, merchant_state, zip, mcc, errors ORDER BY id) as row_num
    FROM transactions_data_cleaned
)
SELECT 
    COUNT(*) as total_duplicate_rows
FROM DuplicatesCTE
WHERE row_num > 1;		--24,888 ROWS

-- Deleting duplicates
WITH DuplicatesCTE AS (
    SELECT id,
        ROW_NUMBER() OVER (PARTITION BY client_id, card_id, date, amount, merchant_id, use_chip, merchant_city, merchant_state, zip, mcc, errors ORDER BY id
        ) as row_num
    FROM transactions_data_cleaned
)
DELETE FROM transactions_data_cleaned
WHERE id IN (
    SELECT id 
    FROM DuplicatesCTE
    WHERE row_num > 1
);

-- 3. [ Structural Errors - Naming conventions, typos, capitalization, notNULLs, extra spaces ]
-- 4. [ Missing Data & NULLs ]
SELECT * FROM transactions_data_cleaned
WHERE id IS NULL OR client_id IS NULL OR card_id IS NULL OR date IS NULL OR amount IS NULL;

-- 5. [ Standardize - Datatype, Numerics]
-- 6. [ Outliers & Column Relationships ]
-- 7. [ Merge, Transform, Drop]


--				[ ANALYSIS ]

--			(Transactions & Business)

-- 1. KPIS
SELECT
    COUNT(t.id) AS total_transactions,
    SUM(t.amount) AS transaction_volume,
    ROUND(AVG(t.amount),2) AS average_transaction_value,
    COUNT(DISTINCT t.client_id) AS total_unique_customers,
    COUNT(DISTINCT t.merchant_id) AS total_unique_merchants,
    COUNT(DISTINCT t.card_id) AS total_unique_cards
FROM transactions_data_cleaned t;

-- 2. Merchant Location
SELECT 
    t.merchant_city,
    t.merchant_state,
    t.zip,
    COUNT(t.id) AS transaction_count,
    SUM(t.amount) AS total_transaction_amount,
    AVG(t.amount) AS average_transaction_amount
FROM transactions_data_cleaned t
GROUP BY t.merchant_city, t.merchant_state, t.zip
ORDER BY total_transaction_amount DESC;

-- 3. Customer Spending
WITH CustomerLocationSpending AS (
    SELECT 
        u.address,
        u.latitude,
        u.longitude,
        u.yearly_income,
        COUNT(t.id) AS total_transactions,
        ROUND(SUM(t.amount), 2) AS total_transaction_amount,
        ROUND(AVG(t.amount), 2) AS avg_transaction_amount,
        ROUND(SUM(t.amount) / u.yearly_income, 4) AS spending_to_income_ratio
    FROM 
        users_data_cleaned u
    JOIN transactions_data_cleaned t ON u.id = t.client_id
    GROUP BY u.address, u.latitude, u.longitude, u.yearly_income
)
SELECT 
    address,
    latitude,
    longitude,
    yearly_income,
    total_transactions,
    total_transaction_amount,
    avg_transaction_amount,
    spending_to_income_ratio,
    NTILE(5) OVER (ORDER BY yearly_income) AS income_quintile, 
    NTILE(5) OVER (ORDER BY total_transaction_amount) AS spending_quintile
FROM 
    CustomerLocationSpending
ORDER BY total_transaction_amount DESC
LIMIT 100;

-- 4. Age Group
SELECT 
    CASE 
        WHEN u.current_age BETWEEN 18 AND 25 THEN '18-25'
        WHEN u.current_age BETWEEN 26 AND 35 THEN '26-35'
        WHEN u.current_age BETWEEN 36 AND 50 THEN '36-50'
        WHEN u.current_age BETWEEN 51 AND 65 THEN '51-65'
        WHEN u.current_age > 65 THEN '65+'
    END AS age_group,
    COUNT(u.id) AS customer_count,
    SUM(t.amount) AS total_transaction_amount,
    COUNT(t.id) AS total_transaction_count,
    SUM(u.total_debt) AS total_debt,
    ROUND(AVG(u.credit_score),0) AS avg_credit_score,
    SUM(u.num_credit_cards) AS total_credit_cards
FROM users_data_cleaned u
LEFT JOIN transactions_data_cleaned t ON u.id = t.client_id
GROUP BY age_group
ORDER BY age_group;

-- 5. Merchant Categories
SELECT 
    mc."Value" AS merchant_category,
    COUNT(t.id) AS transaction_count,
    SUM(t.amount) AS total_transaction_amount,
    AVG(t.amount) AS average_transaction_amount
FROM transactions_data_cleaned t
JOIN mcc_codes_cleaned mc ON t.mcc = mc."Name"
GROUP BY mc."Value" 
ORDER BY total_transaction_amount DESC;

-- 6. Top Merchants
SELECT 
    t.merchant_id,
    mcc."Value" AS mcc_category,
    COUNT(t.id) AS transaction_count, 
    SUM(t.amount) AS total_transaction_amount,
    AVG(t.amount) AS average_transaction_amount 
FROM transactions_data_cleaned t
LEFT JOIN mcc_codes_cleaned mc ON t.mcc = mc."Name"
GROUP BY t.merchant_id, mc."Value"
ORDER BY total_transaction_amount DESC
LIMIT 10;

-- 7. Timeline
SELECT 
    EXTRACT(YEAR FROM t.date) AS transaction_year,
    COUNT(t.id) AS total_transactions,
    SUM(t.amount) AS total_transaction_amount,
    AVG(t.amount) AS avg_transaction_amount,
    COUNT(DISTINCT t.client_id) AS unique_customers,
    COUNT(DISTINCT t.merchant_id) AS unique_merchants, 
    SUM(CASE WHEN t.use_chip = 'Chip Transaction' THEN 1 ELSE 0 END) AS chip_transactions, 
    SUM(CASE WHEN t.use_chip = 'Swipe Transaction' THEN 1 ELSE 0 END) AS swipe_transactions, 
    SUM(CASE WHEN t.use_chip = 'Online Transaction' THEN 1 ELSE 0 END) AS online_transactions,
    SUM(CASE WHEN f."Values" = 'Yes' THEN 1 ELSE 0 END) AS fraud_transactions,
    SUM(CASE WHEN f."Values" = 'Yes' THEN t.amount ELSE 0 END) AS fraud_transaction_amount
FROM transactions_data_cleaned t
LEFT JOIN train_fraud_labels_cleaned f ON t.id = f."target"
GROUP BY transaction_year
ORDER BY transaction_year;

-- 8. Gender
SELECT 
    u.gender, 
    COUNT(u.id) AS total_customers, 
    AVG(u.yearly_income) AS avg_yearly_income,
    SUM(u.total_debt) AS total_debt,
    AVG(u.total_debt) AS avg_debt_per_customer,
    SUM(t.amount) AS total_transaction_amount,
    AVG(t.amount) AS avg_transaction_amount,
    COUNT(t.id) AS total_transactions
FROM users_data_cleaned u
LEFT JOIN transactions_data_cleaned t ON u.id = t.client_id
GROUP BY u.gender
ORDER BY total_customers DESC;


--			(Financial Behavior)

-- 1. KPIs
SELECT 
    COUNT(t.id) / COUNT(DISTINCT t.client_id) AS avg_transaction_frequency,
    ROUND(AVG(u.total_debt) / AVG(u.yearly_income),2) AS debt_to_income_ratio, 
    SUM(t.amount) / SUM(u.yearly_income) AS spending_to_income_ratio,
    ROUND(AVG(u.credit_score),0) AS avg_credit_score
FROM users_data_cleaned u
LEFT JOIN transactions_data_cleaned t ON u.id = t.client_id;

-- 2a. Recurring Transactions for Customers
WITH RecurringTransactions AS ( --Groups transactions for each user and merchant BY MONTH AND YEAR 
    SELECT 
        t.client_id,
        t.merchant_id,
        t.mcc,
        DATE_PART('month', t.date) AS transaction_month,
        DATE_PART('year', t.date) AS transaction_year,
        ROUND(t.amount, 2) AS transaction_amount,
        COUNT(*) AS occurrence_count
    FROM 
        transactions_data_cleaned t
    GROUP BY t.client_id, t.merchant_id, t.mcc, transaction_month, transaction_year, ROUND(t.amount, 2)
    HAVING COUNT(*) >= 3 --At least 3 occurrences to classify as recurring
),
RecurringSummary AS ( --Aggregates the recurring transactions from the above CTE
    SELECT 
        client_id,
        merchant_id,
        transaction_amount,
        mcc,
        COUNT(*) AS recurring_months
    FROM 
        RecurringTransactions
    GROUP BY client_id, merchant_id, transaction_amount, mcc
)
SELECT 
    rs.client_id,
    rs.merchant_id,
    rs.transaction_amount,
    rs.recurring_months, --Number of months this transaction recurred
    mc."Value" AS merchant_category
FROM 
    RecurringSummary rs
LEFT JOIN 
    mcc_codes_cleaned mc ON rs.mcc = mc."Name"
ORDER BY 
    rs.recurring_months DESC, rs.client_id;

-- 2b. Total Recurring Months by Merchant
WITH RecurringTransactions AS (
    SELECT 
        t.client_id,
        t.merchant_id,
        t.mcc,
        DATE_PART('month', t.date) AS transaction_month,
        DATE_PART('year', t.date) AS transaction_year,
        ROUND(t.amount, 2) AS transaction_amount,
        COUNT(*) AS occurrence_count
    FROM 
        transactions_data_cleaned t
    GROUP BY t.client_id, t.merchant_id, t.mcc, transaction_month, transaction_year, ROUND(t.amount, 2)
    HAVING COUNT(*) >= 3
),
RecurringSummary AS (
    SELECT 
        client_id,
        merchant_id,
        mcc,
        COUNT(*) AS recurring_months
    FROM 
        RecurringTransactions
    GROUP BY client_id, merchant_id, mcc
),
MerchantTotals AS ( -- Aggregates recurring months across all customers for each merchant
    SELECT 
        rs.merchant_id,
        rs.mcc,
        SUM(rs.recurring_months) AS total_recurring_months -- Sum recurring months for all customers
    FROM 
        RecurringSummary rs
    GROUP BY rs.merchant_id, rs.mcc
)
SELECT 
    mt.merchant_id,
    mc."Value" AS merchant_category,
    mt.total_recurring_months
FROM 
    MerchantTotals mt
LEFT JOIN mcc_codes_cleaned mc ON mt.mcc = mc."Name"
ORDER BY mt.total_recurring_months DESC
LIMIT 10;

-- 3. Yearly Income
SELECT 
    u.yearly_income,
    COUNT(t.id) AS transaction_count,
    AVG(t.amount) AS average_transaction_amount, 
    SUM(t.amount) AS total_transaction_amount,
    SUM(u.total_debt) AS total_debt,
    AVG(u.total_debt) AS avg_total_debt,
    AVG(u.per_capita_income) AS avg_per_capita_income
FROM users_data_cleaned u
JOIN transactions_data_cleaned t ON u.id = t.client_id
GROUP BY u.yearly_income
ORDER BY u.yearly_income DESC;

-- 4. Credit Score
SELECT 
    CASE 
        WHEN u.credit_score < 580 THEN 'Poor (300-579)'
        WHEN u.credit_score BETWEEN 580 AND 669 THEN 'Fair (580-669)'
        WHEN u.credit_score BETWEEN 670 AND 739 THEN 'Good (670-739)'
        WHEN u.credit_score BETWEEN 740 AND 799 THEN 'Very Good (740-799)'
        ELSE 'Excellent (800-850)'
    END AS credit_score_range,
    COUNT(u.id) AS customer_count,
    AVG(u.yearly_income) AS avg_yearly_income,
    SUM(u.total_debt) AS total_debt,
    AVG(u.total_debt) AS avg_debt_per_customer
FROM users_data_cleaned u
GROUP BY credit_score_range
ORDER BY customer_count DESC;

-- 5. Card Ownership
SELECT 
    u.num_credit_cards, 
    COUNT(u.id) AS customer_count,
    SUM(t.amount) AS total_transaction_amount,
    AVG(u.yearly_income) AS avg_yearly_income
FROM users_data_cleaned u
JOIN transactions_data_cleaned t ON u.id = t.card_id
GROUP BY u.num_credit_cards
ORDER BY u.num_credit_cards;

-- 6. Potential Savings
WITH SpendingSummary AS (
    SELECT 
        t.client_id,
        SUM(t.amount) AS total_spending,
        ROUND(AVG(t.amount), 2) AS avg_transaction_amount
    FROM 
        transactions_data_cleaned t
    GROUP BY t.client_id
)
SELECT 
    u.id AS user_id,
    u.yearly_income,
    ROUND(u.yearly_income * 0.15, 2) AS savings_potential, --choosing .15 
    ss.total_spending,
    ROUND(ss.total_spending / u.yearly_income * 100, 2) AS spending_to_income_ratio
FROM 
    users_data_cleaned u
JOIN SpendingSummary ss ON u.id = ss.client_id
ORDER BY spending_to_income_ratio ASC;

--7. Retirement Age
SELECT 
    u.id AS user_id,
    u.current_age,
    u.retirement_age,
    (u.retirement_age - u.current_age) AS years_to_retirement,
    u.yearly_income,
    u.total_debt,
    ROUND(u.yearly_income * 0.15 * (u.retirement_age - u.current_age), 2) AS potential_savings, --choosing .15 
    ROUND(u.total_debt / u.yearly_income, 2) AS debt_to_income_ratio
FROM 
    users_data_cleaned u
WHERE (u.retirement_age - u.current_age) BETWEEN 0 AND 5 -- Close to retirement, choosing range OF 5 years
ORDER BY years_to_retirement DESC, debt_to_income_ratio DESC;


--			(Fraud & Errors)

-- 1. KPIs
SELECT 
    SUM(CASE WHEN tf."Values" = 'Yes' THEN 1 ELSE 0 END) AS total_fraud_transactions,
    SUM(CASE WHEN tf."Values" = 'Yes' THEN t.amount ELSE 0 END) AS total_fraud_amount,
    ROUND(AVG(CASE WHEN tf."Values" = 'Yes' THEN t.amount ELSE NULL END), 2) AS avg_fraud_transaction,
    ROUND((SUM(CASE WHEN tf."Values" = 'Yes' THEN 1 ELSE 0 END) * 100.0) / NULLIF(COUNT(t.id), 0), 2) AS fraud_rate_pct,
    SUM(CASE WHEN NULLIF(t.errors, '') IS NOT NULL THEN 1 ELSE 0 END) AS total_errors,
    SUM(CASE WHEN NULLIF(t.errors, '') IS NOT NULL THEN t.amount ELSE 0 END) AS total_error_amount,
	ROUND((SUM(CASE WHEN NULLIF(t.errors, '') IS NOT NULL THEN 1 ELSE 0 END) * 100.0) / NULLIF(COUNT(t.id), 0), 2) AS error_rate_pct
FROM transactions_data_cleaned t
LEFT JOIN train_fraud_labels_cleaned tf ON t.id = tf.target
ORDER BY total_fraud_transactions DESC;

-- 2. Errors
SELECT DISTINCT tdc.errors, COUNT(*) -- getting an idea of what all error types
FROM transactions_data_cleaned tdc 
GROUP BY tdc.errors 
ORDER BY COUNT DESC

-- 3. Chip Usage
SELECT 
    t.use_chip,
    SUM(CASE WHEN t.errors != '' THEN 1 ELSE 0 END) AS total_errors
FROM transactions_data_cleaned t
WHERE t.use_chip IN ('Swipe Transaction', 'Chip Transaction', 'Online Transaction')
GROUP BY t.use_chip
ORDER BY t.use_chip DESC;

-- 4a. Fraud Prone Merchant Categories
SELECT 
    mc."Value" AS merchant_category,
    SUM(CASE WHEN "Values" = 'Yes' THEN 1 ELSE 0 END) AS total_fraud_transactions, 
    SUM(CASE WHEN "Values" = 'Yes' THEN t.amount ELSE 0 END) AS total_fraud_amount,
    ROUND(AVG(CASE WHEN "Values" = 'Yes' THEN t.amount ELSE NULL END), 2) AS avg_fraud_transaction
FROM transactions_data_cleaned t
LEFT JOIN train_fraud_labels_cleaned tf ON t.id = tf.target
LEFT JOIN mcc_codes_cleaned mc ON t.mcc = mc."Name"
GROUP BY mc."Value"
HAVING SUM(CASE WHEN "Values" = 'Yes' THEN 1 ELSE 0 END) > 0 -- Only categories with fraud cases
ORDER BY total_fraud_transactions DESC
LIMIT 10;

-- 4b. Fraud Prone Merchants
SELECT 
    t.merchant_id,
    mc."Value" AS merchant_category,
    SUM(CASE WHEN "Values" = 'Yes' THEN 1 ELSE 0 END) AS total_fraud_transactions, 
    SUM(CASE WHEN "Values" = 'Yes' THEN t.amount ELSE 0 END) AS total_fraud_amount,
    ROUND(AVG(CASE WHEN "Values" = 'Yes' THEN t.amount ELSE NULL END), 2) AS avg_fraud_transaction
FROM transactions_data_cleaned t
LEFT JOIN train_fraud_labels_cleaned tf ON t.id = tf.target
LEFT JOIN mcc_codes_cleaned mc ON t.mcc = mc."Name"
GROUP BY t.merchant_id, mc."Value"
HAVING SUM(CASE WHEN "Values" = 'Yes' THEN 1 ELSE 0 END) > 0 -- Only merchants with fraud cases
ORDER BY total_fraud_transactions  DESC
LIMIT 10;

-- 5. User Fraud Rate
WITH FraudFactors AS (
    SELECT 
        u.id AS id,
        u.yearly_income,
        u.total_debt,
        u.num_credit_cards,
        COUNT(t.id) AS total_transactions,
        COUNT(DISTINCT t.merchant_id) AS unique_merchants,
        AVG(t.amount) AS avg_transaction_amount,
        COUNT(CASE WHEN f."Values" = 'Yes' THEN 1 END) AS fraud_transactions,
        ROUND(COUNT(CASE WHEN f."Values" = 'Yes' THEN 1 END) * 100.0 / NULLIF(COUNT(t.id), 0), 2) AS fraud_rate
    FROM 
        users_data_cleaned u
    JOIN transactions_data_cleaned t ON u.id = t.client_id
    LEFT JOIN train_fraud_labels_cleaned f ON t.id = f.target
    GROUP BY u.id, u.yearly_income, u.total_debt, u.num_credit_cards
)
SELECT 
    id,
    yearly_income,
    total_debt,
    num_credit_cards,
    total_transactions,
    unique_merchants,
    ROUND(avg_transaction_amount, 2) AS avg_transaction_amount,
    fraud_transactions,
    ROUND(fraud_rate, 2) AS fraud_rate
FROM 
    FraudFactors
ORDER BY fraud_rate DESC;

-- 6a. Potential Transaction Flags (Structuring, Round Numbers, etc.)
SELECT 
    t.id AS transaction_id,
    t.client_id,
    t.merchant_id,
    t.amount,
    CASE
        WHEN t.amount % 1 = 0 THEN 'Exact Integer'	-- Flag transactions that are exact integers with no decimals
        WHEN t.amount % 100 = 0 THEN 'Ends in 00' -- Flag amounts ending in 00 (e.g., 100, 1500)
        WHEN t.amount % 50 = 0 THEN 'Ends in 50'    -- Flag amounts ending in 50 (e.g., 150, 2050)
        WHEN t.amount % 1000 = 0 THEN 'Multiple of 1000'	 -- Flag large multiples, such as 1000, 5000  
        ELSE 'Normal'	-- anything above this should be covered by structuring 10000$, no point higher = redundant
    END AS number_pattern_flag,
    CASE 
        WHEN t.amount IN (1000, 2000, 5000) THEN 'High-Risk Structuring'
        WHEN t.amount % 5000 = 0 AND t.amount <= 10000 THEN 'Possible Structuring - Large Multiple'
        WHEN t.amount > 10000 THEN 'High Value - Over 10,000'
        ELSE 'Normal'
    END AS structuring_flag
FROM 
    transactions_data_cleaned t
ORDER BY t.amount DESC;

-- 6b. Count of Unusual Amounts
SELECT 
    COUNT(CASE WHEN t.amount % 1 = 0 THEN 1 END) AS exact_integer_count,
    COUNT(CASE WHEN t.amount % 100 = 0 THEN 1 END) AS ends_in_00_count,
    COUNT(CASE WHEN t.amount % 50 = 0 THEN 1 END) AS ends_in_50_count,
    COUNT(CASE WHEN t.amount % 1000 = 0 THEN 1 END) AS multiple_of_1000_count,
    COUNT(CASE WHEN t.amount IN (1000, 2000, 5000) THEN 1 END) AS high_risk_structuring_count,
    COUNT(CASE WHEN t.amount % 5000 = 0 AND t.amount <= 10000 THEN 1 END) AS possible_structuring_count,
    COUNT(CASE WHEN t.amount > 10000 THEN 1 END) AS high_value_over_10000_count
FROM 
    transactions_data_cleaned t;

/* 
 
 -- compare STDEV_transaction amount to avg_transaction amount, lacking precision
 
WITH UserSpending AS (
    SELECT 
        t.client_id,
        AVG(t.amount) AS avg_transaction_amount,
        STDDEV(t.amount) AS stddev_transaction_amount
    FROM transactions_data_cleaned t
    GROUP BY t.client_id
),
HighRiskTransactions AS (
    SELECT 
        t.id,
        t.client_id,
        t.amount,
        u.avg_transaction_amount,
        u.stddev_transaction_amount,
        CASE 
            WHEN t.amount > u.avg_transaction_amount + 3 * u.stddev_transaction_amount THEN 'High Risk'  --3x STDev
            WHEN t.amount > u.avg_transaction_amount + 2 * u.stddev_transaction_amount THEN 'Moderate Risk' --2x STDev
            ELSE 'Low Risk'
        END AS risk_level
    FROM transactions_data_cleaned t
    JOIN UserSpending u ON t.client_id = u.client_id
)
SELECT *
FROM HighRiskTransactions
WHERE risk_level = 'High Risk'
ORDER BY amount DESC;
*/



