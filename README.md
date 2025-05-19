
# 💼 Customer Insights SQL Queries

## 📊 Overview

This project provides a collection of SQL queries to analyze customer behavior across savings and investment products. The queries help financial analysts and product teams:

- Identify high-value customers
- Analyze transaction frequency
- Detect inactive accounts
- Estimate Customer Lifetime Value (CLV)

---

## 🗂️ Project Structure

```

customer-insights-sql/
│
├── sql/
│   ├── high\_value\_customers.sql
│   ├── transaction\_frequency.sql
│   ├── account\_inactivity\_alert.sql
│   └── clv\_estimation.sql
│
└── README.md

````

- `sql/high_value_customers.sql`: Identifies customers with both funded savings and investment plans.
- `sql/transaction_frequency.sql`: Categorizes customers by how often they transact.
- `sql/account_inactivity_alert.sql`: Flags accounts with no transactions in over a year.
- `sql/clv_estimation.sql`: Estimates customer lifetime value based on historical transaction data.

---

## 📂 SQL Query Details

### 1. High-Value Customers by Total Deposits

```sql
SELECT u.id AS owner_id,
       u.name,
       COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN s.id END) AS savings_count,
       COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN s.id END) AS investment_count,
       SUM(s.confirmed_amount) / 100.0 AS total_deposits
FROM users_customuser u
JOIN savings_savingsaccount s ON u.id = s.owner_id
JOIN plans_plan p ON s.plan_id = p.id
WHERE s.confirmed_amount > 0
GROUP BY u.id, u.name
HAVING COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN s.id END) >= 1
   AND COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN s.id END) >= 1
ORDER BY total_deposits DESC;
````

---

### 2. Transaction Frequency Analysis

```sql
WITH customer_transactions AS (
    SELECT s.owner_id,
           COUNT(*) AS total_transactions,
           TIMESTAMPDIFF(MONTH, MIN(s.created_on), NOW()) AS months_active,
           COUNT(*) * 1.0 / NULLIF(TIMESTAMPDIFF(MONTH, MIN(s.created_on), NOW()), 0) AS avg_transactions_per_month
    FROM savings_savingsaccount s
    GROUP BY s.owner_id
)
SELECT CASE
           WHEN avg_transactions_per_month >= 10 THEN 'High Frequency'
           WHEN avg_transactions_per_month >= 3 THEN 'Medium Frequency'
           ELSE 'Low Frequency'
       END AS frequency_category,
       COUNT(*) AS customer_count,
       AVG(avg_transactions_per_month) AS avg_transactions_per_month
FROM customer_transactions
GROUP BY frequency_category
ORDER BY CASE frequency_category
             WHEN 'High Frequency' THEN 1
             WHEN 'Medium Frequency' THEN 2
             WHEN 'Low Frequency' THEN 3
         END;
```

---

### 3. Account Inactivity Alert

```sql
SELECT p.id AS plan_id,
       s.owner_id,
       CASE
           WHEN p.is_regular_savings = 1 THEN 'Savings'
           WHEN p.is_a_fund = 1 THEN 'Investments'
           ELSE 'Other'
       END AS type,
       MAX(s.transaction_date) AS last_transaction_date,
       DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days
FROM plans_plan p
JOIN savings_savingsaccount s ON p.id = s.plan_id
GROUP BY p.id, s.owner_id, p.is_regular_savings, p.is_a_fund
HAVING DATEDIFF(CURDATE(), MAX(s.transaction_date)) > 365
ORDER BY inactivity_days DESC;
```

---

### 4. Customer Lifetime Value (CLV) Estimation

```sql
WITH customer_metrics AS (
    SELECT u.id AS customer_id,
           u.name,
           TIMESTAMPDIFF(MONTH, u.date_joined, NOW()) AS tenure_months,
           COUNT(s.id) AS total_transactions,
           SUM(s.confirmed_amount) * 0.001 AS total_profit
    FROM users_customuser u
    JOIN savings_savingsaccount s ON u.id = s.owner_id
    GROUP BY u.id, u.name, u.date_joined
)
SELECT customer_id,
       name,
       tenure_months,
       total_transactions,
       CASE
           WHEN tenure_months > 0 THEN (total_profit / tenure_months) * 12
           ELSE total_profit
       END AS estimated_clv
FROM customer_metrics
ORDER BY estimated_clv DESC;
```

---

## ✅ Getting Started

1. Clone this repository
2. Navigate to the `sql/` directory
3. Run the queries in your SQL client against your database

> ⚠️ Replace table and column names as needed to match your schema.

---

## 📬 Contact

For questions or suggestions, feel free to reach out via issues or submit a pull request.
