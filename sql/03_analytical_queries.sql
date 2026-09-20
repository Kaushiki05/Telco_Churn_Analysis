-- ==========================================
-- 03: BUSINESS ANALYTICS & COHORT ANALYSIS
-- ==========================================

-- Query 1: Baseline Churn & Total MRR Loss
SELECT 
    COUNT(*) AS total_customers,
    SUM(churn_customers) AS total_churned_customers,
    ROUND(AVG(churn_customers) * 100, 2) AS churn_rate_percentage,
    ROUND(SUM(monthly_revenue_at_risk), 2) AS total_mrr_lost
FROM customers_info;


-- Query 2: Churn Breakdown by Contract Type
SELECT 
    contract,
    COUNT(*) AS total_customers,
    SUM(churn_customers) AS churned_customers,
    ROUND(AVG(churn_customers) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(monthly_revenue_at_risk), 2) AS mrr_at_risk
FROM customers_info
GROUP BY contract
ORDER BY churn_rate_pct DESC;


-- Query 3: High-Risk Segments & Payment Method Thresholds (HAVING Clause)
SELECT 
    paymentmethod,
    COUNT(*) AS total_customers,
    SUM(churn_customers) AS churned_customers,
    ROUND(AVG(churn_customers) * 100, 2) AS churn_rate_pct
FROM customers_info
GROUP BY paymentmethod
HAVING COUNT(*) > 1000 
   AND AVG(churn_customers) > 0.25
ORDER BY churn_rate_pct DESC;


-- Query 4: Customer Tenure Cohort Analysis
SELECT 
    tenure_bins_cohort,
    COUNT(*) AS total_customers,
    SUM(churn_customers) AS churned_customers,
    ROUND(AVG(churn_customers) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(monthly_revenue_at_risk), 2) AS total_mrr_lost,
    ROUND(AVG(monthlycharges), 2) AS avg_monthly_bill
FROM customers_info
GROUP BY tenure_bins_cohort
ORDER BY churn_rate_pct DESC;


-- Query 5: Service Add-On & Tech Support Cross-Tabulation
SELECT 
    internetservice,
    techsupport,
    COUNT(*) AS total_customers,
    SUM(churn_customers) AS churned_customers,
    ROUND(AVG(churn_customers) * 100, 2) AS churn_rate_pct
FROM customers_info
GROUP BY internetservice, techsupport
ORDER BY internetservice, churn_rate_pct DESC;


-- Query 6: Financial Risk Bands Analysis
SELECT 
    churn_risk_score,
    COUNT(*) AS total_customers,
    SUM(churn_customers) AS churned_customers,
    ROUND(AVG(churn_customers) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(monthly_revenue_at_risk), 2) AS total_mrr_at_risk,
    ROUND(AVG(monthlycharges), 2) AS avg_monthly_charges
FROM customers_info
GROUP BY churn_risk_score
ORDER BY churn_risk_score DESC;


-- Query 7: Demographics & Internet Service Breakdown (Conditional Aggregations)
SELECT 
    contract,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN seniorcitizen = 1 THEN churn_customers ELSE 0 END) AS senior_churn_count,
    SUM(CASE WHEN seniorcitizen = 0 THEN churn_customers ELSE 0 END) AS non_senior_churn_count,
    SUM(CASE WHEN internetservice = 'Fiber optic' THEN churn_customers ELSE 0 END) AS fiber_optic_churn_count,
    ROUND(
        SUM(CASE WHEN internetservice = 'Fiber optic' THEN churn_customers ELSE 0 END)::NUMERIC / 
        NULLIF(SUM(CASE WHEN internetservice = 'Fiber optic' THEN 1 ELSE 0 END), 0) * 100, 2
    ) AS fiber_optic_churn_rate_pct
FROM customers_info
GROUP BY contract
ORDER BY total_customers DESC;


-- Query 8: High-Risk Fiber Optic Cohort Revenue Loss (CTEs & Joins)
WITH high_risk_fiber AS (
    SELECT 
        customerid,
        monthlycharges,
        churn_customers,
        monthly_revenue_at_risk
    FROM fct_subscriptions 
    WHERE internetservice = 'Fiber optic'
      AND techsupport = 'No'
),
contract_details AS (
    SELECT 
        customerid,
        contract,
        tenure_bins_cohort
    FROM dim_customers
)
SELECT 
    cd.contract,
    cd.tenure_bins_cohort,
    SUM(hrf.churn_customers) AS total_churn,
    COUNT(hrf.customerid) AS total_customers,
    ROUND(SUM(hrf.monthly_revenue_at_risk), 2) AS total_revenue_lost
FROM high_risk_fiber hrf 
JOIN contract_details cd ON hrf.customerid = cd.customerid
GROUP BY cd.contract, cd.tenure_bins_cohort
ORDER BY total_revenue_lost DESC;


-- Query 9: Billing Quartiles & Dense Ranking Across Contracts (Window Functions)
SELECT 
    d.customerid,
    d.contract,
    f.monthlycharges,
    NTILE(4) OVER (ORDER BY f.monthlycharges DESC) AS revenue_quartile,
    DENSE_RANK() OVER (PARTITION BY d.contract ORDER BY f.monthlycharges DESC) AS rank_within_contract
FROM dim_customers d
JOIN fct_subscriptions f ON d.customerid = f.customerid;