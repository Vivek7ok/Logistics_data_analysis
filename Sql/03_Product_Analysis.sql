-- Product Analysis
-- Which products generate the highest revenue?
select 
product_id,
round(sum(quantity*unit_price*discount)::numeric,1) as revenue
from order_items
group by product_id
order by revenue desc
limit 1;

-- Which products are sold the most by quantity?
select 
product_id,
sum(quantity) as quantity
from order_items
group by product_id
order by quantity desc
limit 1;

-- Which product categories generate the highest revenue?
select 
category,
round(sum(oi.quantity*oi.unit_price*oi.discount)::numeric,1) as revenue
from order_items as oi
join products as p
on p.product_id = oi.product_id
group by category
order by revenue desc
limit 1;

-- Which product categories sell the most units?
select 
category,
sum(quantity) as quantity
from order_items as oi
join products as p
on p.product_id = oi.product_id
group by category
order by quantity desc
limit 1;

-- Which products receive the highest average discount?
select product_id,
round(avg(discount)::numeric,3)as avg_dis
from order_items
group by product_id
order by avg_dis desc
limit 1;

-- Which products are rarely purchased?
select 
product_id,
sum(quantity) as quantity
from order_items
group by product_id
order by quantity 
limit 1;

-- Which products contribute most of total revenue? (Pareto Analysis)
SELECT
    product_id,
    ROUND(
        SUM(quantity * unit_price * (1 - discount)) * 100.0 /
        (SELECT SUM(quantity * unit_price * (1 - discount))FROM order_items)::numeric,3
    ) AS revenue_pct
FROM order_items
GROUP BY product_id
ORDER BY revenue_pct DESC;

-- Which categories have the highest return rate?
SELECT
    category,
    ROUND(
        COUNT(CASE WHEN order_status = 'Returned' THEN 1 END) * 100.0
        / COUNT(*),
        2
    ) AS return_rate
FROM order_items oi
JOIN products p
    ON p.product_id = oi.product_id
JOIN orders o
    ON o.order_id = oi.order_id
GROUP BY category
ORDER BY return_rate DESC;

-- Which warehouse processes the most orders?
select warehouse_id,
count(*) as number_of_orders_procced
from orders
group by warehouse_id
order by number_of_orders_procced desc
limit 1;

-- Which warehouse generates the highest revenue?
select warehouse_id,
sum(total_amount) as revnue
from orders
group by warehouse_id
order by revnue desc
limit 1;

-- Which warehouse has the highest inventory value?
select warehouse_name ,
sum(stock_quantity * unit_price) as value
from warehouses as w
join inventory as i
on i.warehouse_id = w.warehouse_id
join products as p
on i.product_id = p.product_id
group by warehouse_name
order by value desc
limit 1;

-- Which warehouse has the largest number of low-stock products?
SELECT
    warehouse_name,
    COUNT(*) AS low_stock_products
FROM warehouses w
JOIN inventory i
    ON w.warehouse_id = i.warehouse_id
WHERE stock_quantity <= reorder_level
GROUP BY warehouse_name
ORDER BY low_stock_products DESC
LIMIT 1;

-- Which warehouses frequently require inventory replenishment?
SELECT
    warehouse_name,
    COUNT(*) AS replenishment_count 
FROM warehouses w
JOIN inventory i
    ON w.warehouse_id = i.warehouse_id
WHERE stock_quantity <= reorder_level
GROUP BY warehouse_name
ORDER BY replenishment_count  DESC
LIMIT 1;

-- What is the warehouse utilization based on current stock and storage capacity?
SELECT
    warehouse_name,
    SUM(stock_quantity) AS current_stock,
    storage_capacity,
    ROUND(
        SUM(stock_quantity) * 100.0 / storage_capacity,
        2
    ) AS utilization_percentage
FROM warehouses w
JOIN inventory i
    ON w.warehouse_id = i.warehouse_id
GROUP BY
    warehouse_name,
    storage_capacity
ORDER BY utilization_percentage DESC;


-- Shipment & Delivery Analysis
-- Which carrier delivers the most shipments?
select carrier_name,
count(order_id) as toatl_orders
from carriers as c
join shipments as s
on c.carrier_id = s.carrier_id
group by carrier_name;

-- On-Time Delivery Rate
select carrier_name,
ROUND(
    COUNT(*) FILTER (WHERE delay_days <= 0) * 100.0 / COUNT(*),2) AS on_time_rate
from carriers as c
join shipments as s
on c.carrier_id = s.carrier_id
group by carrier_name;

-- Which transport mode (Road, Rail, Air, Sea) is used most frequently?
select transport_mode,
count(order_id) as total_orders
from carriers as c
join shipments as s
on c.carrier_id = s.carrier_id
group by transport_mode
order by total_orders desc
limit 1;

-- Which carrier has the highest shipping cost?
select carrier_name,
max(shipping_cost) max_cost
from carriers as c
join shipments as s
on c.carrier_id = s.carrier_id
group by carrier_name
order by max_cost desc
limit 1;

-- What is the average shipping cost per kilometer by transport mode?
select transport_mode,
round(avg((shipping_cost+fuel_cost)/distance_km)::numeric,1)
from carriers as c
join shipments as s
on c.carrier_id = s.carrier_id
where distance_km > 0
group by transport_mode;
