show columns from savings_savingsaccount; 
-- High Value Customers with Funded Savings Plan and one Funded Investment Plan by Total Deposits
Select u.id AS owner_id,
u.name,
count(distinct case when p.is_regular_savings = 1 then s.id end) as savings_count,
count(distinct case when p.is_a_fund = 1 then s.id end) as investment_count,
sum(s.confirmed_amount)/ 100.0 as total_deposits
from  
users_customuser u 
join 
savings_savingsaccount s on u.id = s.owner_id
join
plans_plan p on s.plan_id = p.id
where s.confirmed_amount > 0
group by u.id, u.name
having count(distinct case when p.is_regular_savings = 1 then s.id end) >= 1
and count(distinct case when p.is_a_fund = 1 then s.id end) >=1 
order by total_deposits desc;

-- Transaction Frequency Analysis
with customer_transactions as (
select s.owner_id, 
count(*) as total_transactions,
timestampdiff(month, min(s.created_on), now()) as months_active,
count(*) * 1.0 / NULLIF(TIMESTAMPDIFF(MONTH, MIN(s.created_on), NOW()), 0)as avg_transactions_per_month
from savings_savingsaccount s
group by s.owner_id
)
select case when avg_transactions_per_month >=10 then 'High frequency'
when avg_transactions_per_month >= 3 then 'Medium Frequency'
else 'Low Frequency'
end as frequency_category,
count(*) as customer_count, 
avg(avg_transactions_per_month) as avg_transactions_per_month
from customer_transactions
group by frequency_category
order by 
case frequency_category
when 'High Frequency' then 1
when 'Medium Frequency' then 2
when 'Low Frequency' then 3
end;

-- Account Inactivity Alert
select p.id as plan_id,
s.owner_id,
case 
when p.is_regular_savings = 1 then 'Savings'
when p.is_a_fund = 1 then 'Investments'
else 'Other'
end as type,
max(s.transaction_date) as last_transaction_date,
datediff(curdate(), max(s.transaction_date)) as Inactivity_Days
from plans_plan p
join savings_savingsaccount s on p.id = s.plan_id
group by p.id, s.owner_id, p.is_regular_savings, p.is_a_fund
having datediff(curdate(), max(s.transaction_date)) > 365
order by Inactivity_Days desc;

-- Customer Lifetime Value (CLV) Estimation
With customer_metrics as (
select u.id as customer_id,
u.name,
TIMESTAMPDIFF(MONTH, u.date_joined, NOW()) as tenure_months, 
count(s.id) as total_transactions,
sum(s.confirmed_amount) * 0.001 as total_profit
from users_customuser u
join savings_savingsaccount s on u.id = s.owner_id
group by u.id, u.name, u.date_joined
)
select customer_id, name, tenure_months, total_transactions,
case when tenure_months > 0 then (total_profit / tenure_months) * 12
else total_profit
end as estimated_clv
from customer_metrics
order by estimated_clv desc;

