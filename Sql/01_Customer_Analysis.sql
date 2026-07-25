-- Customer Analysis
-- Who are our top 10 customers by total revenue?
select customer_name ,round(sum(total_amount)::"numeric",1) as revenue
from customers as c
join orders as o
on c.customer_id = o.customer_id
group by customer_name 
order by revenue desc
limit 10;

-- Which customer type (Retail, Wholesale, Corporate) generates the highest revenue?
select customer_type ,round(sum(total_amount)::"numeric",1) as revenue
from customers as c
join orders as o
on c.customer_id = o.customer_id
group by customer_type
order by revenue desc
limit 1;

-- Which cities contribute the most revenue?
select city,
round(sum(total_amount)::"numeric",1) as revenue, 
round(sum(total_amount)*100/(select sum(total_amount) from orders)::"numeric",2)
from customers as c
join orders as o
on c.customer_id = o.customer_id
group by city
order by revenue desc
limit 1;

-- Which states have the highest number of customers?
select state,
count(customer_id) as number_of_cus
from customers
group by state
order by number_of_cus desc
limit 1;

-- Who are our repeat customers?
select customer_id,
count(*) as number_of_type_order
from orders
group by customer_id
having count(*) > 2
order by number_of_type_order desc;

-- Which customers have placed only one order?
select customer_id,
count(*) as number_of_type_order
from orders
group by customer_id
having count(*) = 1
order by number_of_type_order desc;

-- What is the average order value for each customer type?
select customer_type ,round(avg(total_amount)::"numeric",1) as avg_order_value
from customers as c
join orders as o
on c.customer_id = o.customer_id
group by customer_type;


-- Which type customers have the highest returned order rate?
select customer_type,
count(*)*100/(select count(*) from orders where order_status = 'Returned') as retrun_rate
from customers as c
join orders as o
on c.customer_id = o.customer_id
where order_status = 'Returned'
group by customer_type
order by retrun_rate desc
limit 1;

--
