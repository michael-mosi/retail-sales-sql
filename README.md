# Retail Sales & Customer Intelligence Using PostgreSQL

Name: michael-mosi

SQL analysis of **Duka Smart Electronics**

## Setup

```bash
# 1. Create the database (connected to the default postgres DB)
psql -U postgres -d postgres -f 01_create_database.sql

# 2. Create the tables (schema.sql = course 02 script plus constraints and indexes)
psql -U postgres -d retail_analytics -f schema.sql

# 3. Load and verify the data
psql -U postgres -d retail_analytics -f 03_insert_customers.sql
psql -U postgres -d retail_analytics -f 04_insert_orders.sql
psql -U postgres -d retail_analytics -f 05_verify_data.sql
```

Expected verification: 150 customers, 800 orders, 0 orphan orders, dates January 2025 to September 2026.

## Running the queries

```bash
psql -U postgres -d retail_analytics -f queries.sql
psql -U postgres -d retail_analytics -f queries.sql -o out.txt
```
