create DATABASE finance_project;
USE finance_project;
select *
from customer_financial_profiles
limit 10;

#data cleaning 
SELECT 
COUNT(*) AS total_rows,
COUNT(current_age) AS age_not_null,
COUNT(per_capita_income) AS income_not_null,
COUNT(credit_score) AS credit_not_null
FROM customer_financial_profiles;

#renaming id
ALTER TABLE customer_financial_profiles
CHANGE COLUMN `ï»¿id` id INT;

# Checking duplicates
SELECT id,
    COUNT(*) AS duplicate_count
FROM customer_financial_profiles
GROUP BY id
HAVING COUNT(*) > 1;

#customer table
CREATE TABLE customers AS
SELECT DISTINCT
    client_id,
    current_age,
    birth_year,
    birth_month,
    gender,
    address,
    per_capita_income,
    yearly_income,
    total_debt,
    credit_score,
    num_credit_cards
FROM customer_financial_profiles;

#transaction table
CREATE TABLE transactions AS
SELECT
    transaction_id,
    client_id,
    date,
    amount,
    use_chip,
    merchant_id,
    merchant_city,
    merchant_state,
    zip
FROM customer_financial_profiles;

#DEMOGRAPHIC INSIGHTS
#1) AGE DISTRIBUTION 
SELECT 
    CASE
        WHEN current_age < 25 THEN '18-24'
        WHEN current_age BETWEEN 25 AND 34 THEN '25-34'
        WHEN current_age BETWEEN 35 AND 44 THEN '35-44'
        WHEN current_age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END AS age_group,
    COUNT(*) AS customer_count
FROM customers
GROUP BY age_group
ORDER BY customer_count ;

#2) GENDER SPLIT
SELECT gender, COUNT(*) AS count
FROM customers
GROUP BY gender;

#3) STATE WISE CUSTOMER
SELECT 
    SUBSTRING_INDEX(address, ',', -1) AS state,
    COUNT(*) AS customer_count
FROM customers
GROUP BY state
ORDER BY customer_count DESC;

#STEP 2 — FINANCIAL PROFILE ANALYSIS
#1) Average Income by Age Group
SELECT 
    CASE
        WHEN current_age < 30 THEN 'Under 30'
        WHEN current_age BETWEEN 30 AND 40 THEN '30-40'
        WHEN current_age BETWEEN 40 AND 50 THEN '40-50'
        ELSE '50+'
    END AS age_group,
    AVG(yearly_income) AS avg_income
FROM customers
GROUP BY age_group;

#2)Credit Score Segmentation
SELECT 
    CASE
        WHEN credit_score < 600 THEN 'Poor'
        WHEN credit_score BETWEEN 600 AND 700 THEN 'Fair'
        WHEN credit_score BETWEEN 701 AND 800 THEN 'Good'
        ELSE 'Excellent'
    END AS credit_category,
    COUNT(*) AS customer_count
FROM customers
GROUP BY credit_category;

#3)Debt-to-Income Ratio
SELECT 
    client_id,
    total_debt / yearly_income AS debt_income_ratio
FROM customers
ORDER BY debt_income_ratio DESC
LIMIT 100
;

#STEP 3 — TRANSACTION ANALYSIS

SET SQL_SAFE_UPDATES = 0;
UPDATE transactions
SET date = STR_TO_DATE(date, '%d-%m-%Y');
ALTER TABLE transactions
MODIFY COLUMN date DATE;
SELECT MIN(date), MAX(date)
FROM transactions;

#1) Monthly Revenue Trend
SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    SUM(amount) AS monthly_revenue
FROM transactions
GROUP BY month
ORDER BY month;

#2) Average Transaction Value
SELECT AVG(amount) AS avg_transaction
FROM transactions;

#3) Revenue by State
SELECT 
merchant_state,
sum(amount) as total_revenue
from transactions
group by merchant_state
order by total_revenue desc;

#4) Revenue by city
select 
merchant_city,
sum(amount) as total_revenue
from transactions
group by merchant_city
order by total_revenue desc;

#CUSTOMER VALUE ANALYSIS
#1) CLV
SELECT 
    client_id,
    SUM(amount) AS lifetime_value
FROM transactions
GROUP BY client_id
ORDER BY lifetime_value DESC;

#2) Customer Total Spending by State
select 
client_id,
merchant_state,
sum(amount) as total_spending
from transactions
group by client_id, merchant_state
order by client_id, merchant_state desc;

#3) customer total spending by city
select
client_id, merchant_city,
sum(amount) as total_spending 
from transactions
group by client_id, merchant_city
order by client_id, merchant_city desc;

#4) CLV by State (Aggregated)
SELECT 
    merchant_state,
    AVG(customer_spend) AS avg_clv
FROM (
    SELECT 
        client_id,
        merchant_state,
        SUM(amount) AS customer_spend
    FROM transactions
    GROUP BY client_id, merchant_state
) AS state_clv
GROUP BY merchant_state
ORDER BY avg_clv DESC;

#5) Which State Each Customer Spends Most In(For each customer, which state has the highest total spending?)
SELECT *
FROM (
    SELECT 
        client_id,
        merchant_state,
        SUM(amount) AS total_spending,
        RANK() OVER (PARTITION BY client_id ORDER BY SUM(amount) DESC) AS rnk
    FROM transactions
    GROUP BY client_id, merchant_state
) AS ranked
WHERE rnk = 1;

#6) High Value Customers
SELECT COUNT(*) 
FROM (
    SELECT client_id
    FROM transactions
    GROUP BY client_id
    HAVING SUM(amount) > 10000
) AS high_value;
