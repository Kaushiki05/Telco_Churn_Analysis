-- ==========================================
-- 02: DATA INGESTION & DATA SANITY CHECKS
-- ==========================================

-- Option 1: PostgreSQL Native COPY Command (Run in psql / admin tool)
-- Note: Replace the path below with your actual local file path
COPY public.customers_info
FROM 'C:/telco-churn-analytics/data/processed/telco_churn_processed.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ','
);

-- Data Ingestion Validation Checks
SELECT COUNT(*) AS total_rows_imported FROM customers_info;

SELECT 
    customerid, 
    tenure_bins_cohort, 
    churn_risk_score, 
    monthly_revenue_at_risk, 
    churn_customers
FROM customers_info
LIMIT 5;