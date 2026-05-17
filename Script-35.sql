set search_path to sales_data;
create table sales_data(
customer_id TEXT,
product_name TEXT,
Quantity TEXT,
total_price TEXT,
sales_rep TEXT,
payment_method TEXT);

select * from sales_data;

-- fixing the total_price column
UPDATE sales_data 
SET total_price = (quantity::INTEGER) * 19.99
WHERE total_price LIKE 'error%';

select * from sales_data;

-- fixing the product_name and sales_rep column
-- capitalizing the leters and standardizing the special characters
-- triming to remove spaces
update sales_data
set product_name = replace(INITCAP(product_name), 'Ã±', 'ñ');

update sales_data
set product_name = trim(product_name);

update sales_data
set sales_rep = TRIM(INITCAP(sales_rep));

UPDATE sales_data
SET sales_rep = REPLACE(sales_rep, '-', ' - ');

select * from sales_data;


-- Re-creating the clean table as cleaned_sales
CREATE TABLE clean_sales AS
SELECT * FROM sales_data;

select * from clean_sales;

-- Convert total_price from text to decimal
ALTER TABLE clean_sales 
ALTER COLUMN total_price TYPE DECIMAL(10,2) USING total_price::DECIMAL;

-- Convert quantity from text to integer
ALTER TABLE clean_sales 
ALTER COLUMN quantity TYPE INTEGER USING quantity::INTEGER;

-- Convert customer_id from text to integer
ALTER TABLE clean_sales 
ALTER COLUMN customer_id TYPE INTEGER USING customer_id::INTEGER;
-- Check the data types now
SELECT 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_name = 'clean_sales'
ORDER BY ordinal_position;

-- 1.top 5 sales rep by revenue
select 
    sales_rep,
    ROUND(SUM(total_price), 2) as total_revenue
FROM clean_sales
WHERE sales_rep IS NOT NULL
group by sales_rep
order by total_revenue desc
limit 10;

-- revenue distribution by method of payments
select 
    payment_method,
    ROUND(SUM(total_price), 2) as total_revenue,
    COUNT(*) as transaction_count,
    ROUND(100.0 * SUM(total_price) / SUM(SUM(total_price)) OVER(), 2) as revenue_percentage
from clean_sales
group by payment_method
order by total_revenue desc;

-- most valuable customer with most spendings
select 
    customer_id,
    ROUND(SUM(total_price), 2) as total_spent,
    COUNT(*) as number_of_orders,
    ROUND(AVG(total_price), 2) as avg_order_value
from clean_sales
group by customer_id
order by total_spent desc
limit 5;

-- products that are low on demand
select 
    product_name,
    COUNT(*) as times_ordered,
    SUM(quantity) as total_units_sold,
    ROUND(SUM(total_price), 2) as total_revenue
from clean_sales
group by product_name
order by times_ordered asc
limit 10;

select * from clean_sales;
-- sales summary view(fact table)
create view vw_sales_summary as
select 
    customer_id,
    product_name,
    quantity,
    total_price,
    sales_rep,
    payment_method,
    case 
        when total_price > 1000 then 'High Value'
        when total_price > 500 then 'Medium Value'
        else 'Low Value'
    end as order_segment,
    case 
        when quantity > 50 then 'Bulk Order'
        when quantity > 20 then 'Large Order'
        else 'Regular Order'
    end as order_size
from clean_sales;

--creatig  sales rep perfomance 
create view vw_sales_rep_performance as
select 
    sales_rep,
    COUNT(*) as total_transactions,
    ROUND(SUM(total_price), 2) as total_revenue,
    ROUND(AVG(total_price), 2) as avg_transaction_value,
    SUM(quantity) as total_units_sold,
    ROUND(AVG(quantity), 1) as avg_units_per_transaction
from clean_sales
where sales_rep IS NOT null
group by sales_rep
order by total_revenue desc;  

-- creating the perfomance view
create view vw_product_performance as
select 
    product_name,
    SUM(quantity) as total_units_sold,
    ROUND(SUM(total_price), 2) as total_revenue,
    COUNT(*) as number_of_orders,
    ROUND(AVG(total_price), 2) as avg_order_value
from clean_sales
group by product_name
order by total_revenue desc;

-- pament method analysis view
create view vw_payment_analysis as
select 
    payment_method,
    COUNT(*) as transaction_count,
    ROUND(SUM(total_price), 2) as total_revenue,
    ROUND(AVG(total_price), 2) as avg_transaction_value,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as transaction_percentage,
    ROUND(100.0 * SUM(total_price) / SUM(SUM(total_price)) OVER(), 2) as revenue_percentage
from clean_sales
group by payment_method
order by total_revenue desc;

-- customer analysis views
create view vw_top_customers as
select 
    customer_id,
    ROUND(SUM(total_price), 2) as total_spent,
    COUNT(*) as orders_count,
    SUM(quantity) as total_items_bought
from clean_sales
group by customer_id
order by total_spent desc
limit 10;
