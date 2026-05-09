## Sales Intelligence Platform (OLTP → OLAP Data Pipeline)
## Overview

This project builds an end-to-end data pipeline that transforms raw retail sales data into a structured system for analytics.

It demonstrates:

- Data cleaning and transformation (Pandas)
- OLTP and OLAP data modeling
- Data loading into PostgreSQL
- Analytical readiness using a star schema

---
## Problem

Retail data is often fragmented and difficult to analyze due to:

- Lack of a centralized data model
- Inconsistent formats
- Manual reporting processes

This project creates a scalable data foundation for reliable analysis.

---
## Architecture
Raw CSV → Pandas (Cleaning & Transformation) → PostgreSQL  
         → OLTP (Normalized Schema)  
         → OLAP (Star Schema) → Analytics

---
## Data Modeling
### OLTP (Transactional Schema)
- Supports transactional operations
- Tables: customers, products, payments, locations, orders 

![](./flowcart_ERD_OLTP.png)

### OLAP (Data Warehouse - Star Schema)
- Optimized for analytical queries
- Supports aggregations and reporting
- Fact Table: orders, amount (unit price), quantity, profit
- Dimension Tables: customers, products, locations, payments,dates

![](./flowcart_ERD_OLAP.png)

---
## ETL Pipeline
1. Data Cleaning (Pandas)
- Standardized column names
- Removed duplicates
- Converted data types
- Generated surrogate keys
2. Transformation
- Built dimension tables
- Merged dimension keys into dataset
- Created fact table
3. Data Loading (PostgreSQL)
- Created schemas: transact (OLTP), flowcart (OLAP)
- Bulk inserts using psycopg2
- Transaction handling with rollback

---
## Technologies Used
- Python 3
- Pandas
- PostgreSQL
- psycopg2

---
## How to Run the Project

### 1. Clone Repository
```bash
git clone <https://github.com/Chukwuemeka971/retail-data-pipeline-oltp-olap>
cd retail-data-pipeline-oltp-olap
```

---
### 2. Install dependencies
</> Bash
```
pip install pandas psycopg2 python-dotenv
```

---
### 3. Create a .env File
Create a .env file in the project root directory
```
</> env

db_host=localhost
db_name=flowcart
db_user=postgres
db_password=your_password
db_port=5432
```

---
### 4. Start PostgreSQL
Ensure PostgreSQL is running and create a database named:
```
flowcart
```

---
### 5. Run Data Cleaning Pipeline
This notebook:

- Cleans raw retail data
- standardizes columns
- Creates dimension & fact tables
- Exports cleaned CSV files
```
</> Bash

jupyter notebook notebooks/data_cleaning.ipynb
```
Generated files will be stored in
```
data/clean_dataset/
data/transactions_data/
```
---
### 6. Load Data into PostgreSQL
This notebook:
- Connects to PostgreSQL using environment variables
- Creates OLTP(transact) and OLAP(flowcart) schemas
- Creates tables
- Loads cleaned CSV data into PostgreSQL
```
</> Bash

jupyter notebook notebooks/load_to_database.ipynb
```
### 6. Verify Data Load
```
</> SQL

SELECT COUNT(*) FROM flowcart.orders;
SELECT COUNT(*) FROM transact.orders;
```

## Analytical Validation
#### Note: amount represents unit price
#### Revenue = amount × quantity
### Top 10 products by profit
```
</> SQL

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
```
### High Revenue Cities (Top 5%)
```
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
```
### Average Sales per product
```
WITH monthly_sales AS (
    SELECT 
        o.product_id,
        d.year,
        d.month_name,
        SUM(o.amount * o.quantity) AS monthly_sales
    FROM flowcart.orders o
    JOIN flowcart.dates d 
        ON o.date_id = d.date_id
    GROUP BY o.product_id, d.year, d.month_name
)

SELECT 
    p.product_id,
    p.category,
    p.sub_category,
    ROUND(AVG(m.monthly_sales)::numeric, 2) AS avg_monthly_sales
FROM monthly_sales m
JOIN flowcart.products p 
    ON m.product_id = p.product_id
GROUP BY p.product_id, p.category, p.sub_category
ORDER BY avg_monthly_sales DESC;
```
  
   
   
  
   


