-- ==========================================
-- 01: DATABASE SCHEMA & TABLE DEFINITIONS
-- ==========================================

-- Raw Staging Table
DROP TABLE IF EXISTS customers_info CASCADE;

CREATE TABLE customers_info (
    customerid VARCHAR(50) PRIMARY KEY,
    gender VARCHAR(20),
    seniorcitizen INT,
    partner VARCHAR(10),
    dependents VARCHAR(10),
    tenure INT,
    phoneservice VARCHAR(10),
    multiplelines VARCHAR(30),
    internetservice VARCHAR(30),
    onlinesecurity VARCHAR(30),
    onlinebackup VARCHAR(30),
    deviceprotection VARCHAR(30),
    techsupport VARCHAR(30),
    streamingtv VARCHAR(30),
    streamingmovies VARCHAR(30),
    contract VARCHAR(30),
    paperlessbilling VARCHAR(10),
    paymentmethod VARCHAR(50),
    monthlycharges NUMERIC(10, 2),
    totalcharges NUMERIC(10, 2),
    churn VARCHAR(10),
    
    -- Feature Engineered Columns (from Python ETL)
    tenure_bins_cohort VARCHAR(30),
    churn_risk_score INT,
    churn_customers INT,
    monthly_revenue_at_risk NUMERIC(10, 2)
);

-- ==========================================
-- DIMENSION & FACT TABLES (STAR SCHEMA)
-- ==========================================

-- 1. Customer Dimension Table
DROP TABLE IF EXISTS dim_customers CASCADE;
CREATE TABLE dim_customers AS 
SELECT 
    customerid, 
    gender, 
    seniorcitizen, 
    tenure, 
    tenure_bins_cohort,
    contract, 
    paymentmethod 
FROM customers_info;

ALTER TABLE dim_customers ADD PRIMARY KEY (customerid);

-- 2. Services & Financials Fact Table
DROP TABLE IF EXISTS fct_subscriptions CASCADE;
CREATE TABLE fct_subscriptions AS 
SELECT 
    customerid, 
    internetservice, 
    techsupport, 
    monthlycharges, 
    churn_customers, 
    monthly_revenue_at_risk,
    churn_risk_score
FROM customers_info;

ALTER TABLE fct_subscriptions 
ADD CONSTRAINT fk_fct_customer 
FOREIGN KEY (customerid) REFERENCES dim_customers(customerid);

-- ==========================================
-- EXECUTIVE REPORTING VIEW FOR POWER BI
-- ==========================================
CREATE OR REPLACE VIEW executive_churn_summary AS
SELECT 
    d.customerid,
    d.gender,
    d.seniorcitizen,
    d.tenure,
    d.tenure_bins_cohort,
    d.contract,
    d.paymentmethod,
    f.internetservice,
    f.techsupport,
    f.monthlycharges,
    f.churn_customers,
    f.monthly_revenue_at_risk,
    f.churn_risk_score
FROM dim_customers d
JOIN fct_subscriptions f ON d.customerid = f.customerid;