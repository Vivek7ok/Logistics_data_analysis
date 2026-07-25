-- Sales Analysis
-- How many orders were placed each month?
SELECT
    EXTRACT(YEAR FROM order_date ::date) AS year,
    EXTRACT(MONTH FROM order_date ::date) AS month,
    COUNT(*) AS number_of_orders
FROM orders
GROUP BY
    EXTRACT(YEAR FROM order_date ::date),
    EXTRACT(MONTH FROM order_date ::date)
ORDER BY
    year,
    month;

-- What is the month-over-month revenue growth?
SELECT
    EXTRACT(YEAR FROM order_date ::date) AS year,
    EXTRACT(MONTH FROM order_date ::date) AS month,
    sum(total_amount) AS revenue,
	sum(sum(total_amount)) 
	over(PARTITION BY EXTRACT(YEAR FROM order_date::DATE) 
	order by EXTRACT(YEAR FROM order_date ::date)) AS running_revenue
FROM orders
GROUP BY
    EXTRACT(YEAR FROM order_date ::date),
    EXTRACT(MONTH FROM order_date ::date)
ORDER BY
    year,
    month;

-- Which months recorded the highest sales?
SELECT
    EXTRACT(YEAR FROM order_date ::date) AS year,
    EXTRACT(MONTH FROM order_date ::date) AS month,
    sum(total_amount) AS revenue
FROM orders
GROUP BY
    EXTRACT(YEAR FROM order_date ::date),
    EXTRACT(MONTH FROM order_date ::date)
ORDER BY revenue desc
limit 1;

-- How many orders are Delivered, Cancelled, Returned, In Transit, and Processing?
select 
order_status,
count(*) as number_of_order
from orders
group by order_status;

-- What percentage of orders were cancelled?
select 
order_status,
count(*)*100/(select count(*) from orders) as per_of_cancel
from orders
where order_status = 'Cancelled'
group by order_status;

-- What percentage of orders were returned?
select 
order_status,
count(*)*100/(select count(*) from orders) as per_of_cancel
from orders
where order_status = 'Returned'
group by order_status;

--
