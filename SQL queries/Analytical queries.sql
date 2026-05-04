--- Total Revenue and profit
SELECT 
    SUM(amount * quantity) AS total_revenue,
    SUM(profit) AS total_profit
FROM flowcart.orders;

--- Top 10 products by profit
SELECT 
    p.category,
    p.sub_category,
    SUM(o.profit) AS total_profit
FROM flowcart.orders o
JOIN flowcart.products p 
    ON o.product_id = p.product_id
GROUP BY p.category, p.sub_category
ORDER BY total_profit DESC
LIMIT 10;

--- Top 10 products by revenue
SELECT 
    p.category,
    p.sub_category,
    SUM(o.amount * o.quantity) AS revenue
FROM flowcart.orders o
JOIN flowcart.products p 
    ON o.product_id = p.product_id
GROUP BY p.category, p.sub_category
ORDER BY revenue DESC
LIMIT 10;

---Revenue by city
SELECT 
    l.city,
    l.state,
    SUM(o.amount * o.quantity) AS revenue
FROM flowcart.orders o
JOIN flowcart.locations l 
    ON o.location_id = l.location_id
GROUP BY l.city, l.state
ORDER BY revenue DESC
LIMIT 5;

---Top 5 customers by revenue
SELECT 
    c.customer_name,
    SUM(o.amount * o.quantity) AS total_spent
FROM flowcart.orders o
JOIN flowcart.customers c 
    ON o.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY total_spent DESC
LIMIT 5;

--- Monthly Revenue Trend
SELECT 
    d.year,
    d.month_name,
    SUM(o.amount * o.quantity) AS monthly_revenue
FROM flowcart.orders o
JOIN flowcart.dates d 
    ON o.date_id = d.date_id
GROUP BY d.year, d.month_name
ORDER BY d.year, MIN(d.date_id);

--Revenue by payment method
SELECT 
    p.payment_mode,
    SUM(o.amount * o.quantity) AS revenue
FROM flowcart.orders o
JOIN flowcart.payments p 
    ON o.payment_id = p.payment_id
GROUP BY p.payment_mode
ORDER BY revenue DESC;

--Top Category per Year (Revenue-Based)
SELECT *
FROM (
    SELECT 
        d.year,
        p.category,
        SUM(o.amount * o.quantity) AS revenue,
        RANK() OVER (
            PARTITION BY d.year 
            ORDER BY SUM(o.amount * o.quantity) DESC
        ) AS rank
    FROM flowcart.orders o
    JOIN flowcart.products p 
        ON o.product_id = p.product_id
    JOIN flowcart.dates d 
        ON o.date_id = d.date_id
    GROUP BY d.year, p.category
) ranked
WHERE rank = 1;

-- High Revenue Cities (Top 5%)
WITH city_revenue AS (
    SELECT 
        l.city,
        SUM(o.amount * o.quantity) AS revenue
    FROM flowcart.orders o
    JOIN flowcart.locations l 
        ON o.location_id = l.location_id
    GROUP BY l.city
)
SELECT *
FROM city_revenue
WHERE revenue > (
    SELECT PERCENTILE_CONT(0.95) 
    WITHIN GROUP (ORDER BY revenue)
    FROM city_revenue
);

--  City Performance Segmentation Based on Revenue
WITH city_revenue AS (
    SELECT 
        l.city,
        SUM(o.amount * o.quantity) AS revenue
    FROM flowcart.orders o
    JOIN flowcart.locations l 
        ON o.location_id = l.location_id
    GROUP BY l.city
),

percentiles AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue) AS p25,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue) AS p75,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY revenue) AS p95
    FROM city_revenue
)

SELECT 
    c.city,
    c.revenue,
    CASE 
        WHEN c.revenue >= p.p95 THEN 'Elite (Top 5%)'
        WHEN c.revenue >= p.p75 THEN 'Strong (75th–95th)'
        WHEN c.revenue >= p.p25 THEN 'Mid-tier (25th–75th)'
        ELSE 'Low Performer (Bottom 25%)'
    END AS city_segment
FROM city_revenue c
CROSS JOIN percentiles p
ORDER BY c.revenue DESC;




