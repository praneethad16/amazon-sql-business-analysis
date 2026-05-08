CREATE TABLE amazon_brazil.customers (
    customer_id VARCHAR PRIMARY KEY,
    customer_unique_id VARCHAR,
    customer_zip_code_prefix INT
);
CREATE TABLE amazon_brazil.orders (
    order_id VARCHAR PRIMARY KEY,
    customer_id VARCHAR,
    order_status VARCHAR,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);
CREATE TABLE amazon_brazil.payments (
    order_id VARCHAR,
    payment_sequential INT,
    payment_type VARCHAR,
    payment_installments INT,
    payment_value NUMERIC
);
CREATE TABLE amazon_brazil.sellers (
    seller_id VARCHAR PRIMARY KEY,
    seller_zip_code_prefix INT
);
CREATE TABLE amazon_brazil.products (
product_id VARCHAR PRIMARY KEY,
product_category_name VARCHAR,
product_name_length INTEGER,
product_description_length INTEGER,
product_photos_qty INTEGER,
product_weight_g INTEGER,
product_length_cm INTEGER,
product_height_cm INTEGER,
product_width_cm INTEGER
);
CREATE TABLE amazon_brazil.order_items (
order_id VARCHAR,
order_item_id INTEGER,
product_id VARCHAR,
seller_id VARCHAR,
shipping_limit_date TIMESTAMP,
price NUMERIC,
freight_value NUMERIC
);

-- Question 1:
-- To simplify financial reports, calculate the average payment value for each payment type,
-- round it to the nearest integer, and display results in ascending order.

SELECT 
    payment_type,
    ROUND(AVG(payment_value)) AS rounded_avg_payment
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY rounded_avg_payment ASC;

-- Question 2:
-- Calculate the percentage of total orders for each payment type,
-- rounded to one decimal place, and display in descending order.

SELECT payment_type, 
ROUND(COUNT(order_id) * 100.0 / SUM(COUNT(order_id)) OVER (),1) AS percentage_orders
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY percentage_orders DESC;

-- Question 3:
-- Identify all products priced between 100 and 500 BRL that contain the word 'Smart' in their name,
-- and display them sorted by price in descending order.

SELECT 
    oi.product_id,
    oi.price
FROM amazon_brazil.order_items oi
JOIN amazon_brazil.products p
    ON oi.product_id = p.product_id
WHERE 
    oi.price BETWEEN 100 AND 500
    AND p.product_category_name ILIKE '%smart%'
ORDER BY oi.price DESC;

-- Question 4:
-- Determine the top 3 months with the highest total sales value,
-- rounded to the nearest integer.

SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price)) AS total_sales
FROM amazon_brazil.orders o
JOIN amazon_brazil.order_items oi
    ON o.order_id = oi.order_id
GROUP BY month
ORDER BY total_sales DESC;

-- Question 5:
-- Find product categories where the difference between maximum and minimum prices exceeds 500 BRL.

SELECT 
    p.product_category_name,
    MAX(oi.price) - MIN(oi.price) AS price_difference
FROM amazon_brazil.order_items oi
JOIN amazon_brazil.products p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
HAVING MAX(oi.price) - MIN(oi.price) > 500
ORDER BY price_difference DESC;

-- Question 6:
-- Identify payment types with the least variation in transaction amounts,
-- using standard deviation and sorting by smallest first.

SELECT 
    payment_type,
    ROUND(STDDEV(payment_value), 2) AS std_deviation
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY std_deviation ASC;

-- Question 7:
-- Retrieve products where the product category name is missing
-- or contains only a single character.

SELECT 
    product_id,
    product_category_name
FROM amazon_brazil.products
WHERE 
    product_category_name IS NULL
    OR LENGTH(product_category_name) = 1;

-- Part II - Question 1:
-- Segment orders into value ranges and calculate the count of each payment type within those segments.

SELECT 
    CASE 
        WHEN oi.price < 200 THEN 'Low'
        WHEN oi.price BETWEEN 200 AND 1000 THEN 'Medium'
        ELSE 'High'
    END AS order_value_segment,
    p.payment_type,
    COUNT(*) AS count
FROM amazon_brazil.order_items oi
JOIN amazon_brazil.payments p
    ON oi.order_id = p.order_id
GROUP BY order_value_segment, p.payment_type
ORDER BY count DESC;

-- Part II - Question 2:
-- Calculate minimum, maximum, and average price for each product category,
-- and sort results by average price in descending order.

SELECT 
    p.product_category_name,
    MIN(oi.price) AS min_price,
    MAX(oi.price) AS max_price,
    ROUND(AVG(oi.price), 2) AS avg_price
FROM amazon_brazil.order_items oi
JOIN amazon_brazil.products p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY avg_price DESC; 

-- Part II - Question 3:
-- Identify customers who have placed more than one order and display their total order count.

SELECT 
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM amazon_brazil.orders o
JOIN amazon_brazil.customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(o.order_id) > 1
ORDER BY total_orders DESC;

-- Part II - Question 4:
-- Categorize customers into New, Returning, and Loyal based on their total order count.

WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.customers c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT 
    customer_unique_id,
    CASE 
        WHEN total_orders = 1 THEN 'New'
        WHEN total_orders BETWEEN 2 AND 4 THEN 'Returning'
        ELSE 'Loyal'
    END AS customer_type
FROM customer_orders;

-- Part II - Question 5:
-- Calculate total revenue for each product category and display the top 5 categories.

SELECT 
    p.product_category_name,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM amazon_brazil.order_items oi
JOIN amazon_brazil.products p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC;

-- Part III - Question 1:
-- Calculate total sales for each season based on order purchase dates.

SELECT 
    season,
    ROUND(SUM(price), 2) AS total_sales
FROM (
    SELECT 
        oi.price,
        CASE 
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (9, 10, 11) THEN 'Autumn'
            ELSE 'Winter'
        END AS season
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.order_items oi
        ON o.order_id = oi.order_id
) AS seasonal_data
GROUP BY season
ORDER BY total_sales DESC;

-- Part III - Question 2:
-- Identify products whose total quantity sold is above the overall average.

SELECT 
    product_id,
    COUNT(order_item_id) AS total_quantity_sold
FROM amazon_brazil.order_items
GROUP BY product_id
HAVING COUNT(order_item_id) > (
    SELECT AVG(product_count)
    FROM (
        SELECT COUNT(order_item_id) AS product_count
        FROM amazon_brazil.order_items
        GROUP BY product_id
    ) AS avg_table
)LIMIT 10;

-- Part III - Question 3:
-- Calculate total monthly revenue for the year 2018.

SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM amazon_brazil.orders o
JOIN amazon_brazil.order_items oi
    ON o.order_id = oi.order_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
GROUP BY month
ORDER BY month;

-- Part III - Question 4:
-- Segment customers based on purchase frequency and count the number of customers in each segment.

WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.customers c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),
categorized AS (
    SELECT 
        CASE 
            WHEN total_orders BETWEEN 1 AND 2 THEN 'Occasional'
            WHEN total_orders BETWEEN 3 AND 5 THEN 'Regular'
            ELSE 'Loyal'
        END AS customer_type
    FROM customer_orders
)

SELECT 
    customer_type,
    COUNT(*) AS count
FROM categorized
GROUP BY customer_type
ORDER BY count DESC;

-- Part III - Question 5:
-- Rank customers based on their average order value and display the top 20.

WITH order_values AS (
    -- Total value per order
    SELECT 
        o.order_id,
        o.customer_id,
        SUM(oi.price) AS order_total
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.customer_id
),
customer_avg AS (
    -- Average order value per customer
    SELECT 
        c.customer_id,
        AVG(ov.order_total) AS avg_order_value
    FROM order_values ov
    JOIN amazon_brazil.customers c
        ON ov.customer_id = c.customer_id
    GROUP BY c.customer_id
)
SELECT 
    customer_id,
    ROUND(avg_order_value, 2) AS avg_order_value,
    RANK() OVER (ORDER BY avg_order_value DESC) AS customer_rank
FROM customer_avg
ORDER BY customer_rank
LIMIT 20;

-- Part III - Question 6:
-- Calculate monthly cumulative sales for each product.

WITH monthly_sales AS (
    SELECT 
        oi.product_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS sale_month,
        SUM(oi.price) AS monthly_total
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY oi.product_id, sale_month
)

SELECT 
    product_id,
    sale_month,
    SUM(monthly_total) OVER (
        PARTITION BY product_id 
        ORDER BY sale_month
    ) AS total_sales
FROM monthly_sales
ORDER BY product_id, sale_month;

-- Part III - Question 7:
-- Calculate monthly sales and month-over-month growth for each payment type in 2018.

WITH monthly_sales AS (
    SELECT 
        p.payment_type,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS sale_month,
        SUM(oi.price) AS monthly_total
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.order_items oi
        ON o.order_id = oi.order_id
    JOIN amazon_brazil.payments p
        ON o.order_id = p.order_id
    WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
    GROUP BY p.payment_type, sale_month
)
SELECT 
    payment_type,
    sale_month,
    ROUND(monthly_total, 2) AS monthly_total,
    ROUND(
        (monthly_total - LAG(monthly_total) OVER (
            PARTITION BY payment_type 
            ORDER BY sale_month
        )) 
        * 100.0 
        / LAG(monthly_total) OVER (
            PARTITION BY payment_type 
            ORDER BY sale_month
        ),
        2
    ) AS monthly_change
FROM monthly_sales
ORDER BY payment_type, sale_month;











