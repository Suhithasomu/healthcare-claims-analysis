
-- ============================================================================
-- HEALTHCARE CLAIMS ANALYTICS - SQL QUERIES
-- Business Questions for Claims Analysis & Member Risk Segmentation
-- ============================================================================

-- QUERY 1: Calculate total costs and claim counts by member
-- Business Question: Who are our highest-cost members?
-- ============================================================================
SELECT 
    member_id,
    COUNT(claim_id) AS total_claims,
    SUM(claim_cost) AS total_cost,
    AVG(claim_cost) AS avg_cost_per_claim
FROM claim_data
GROUP BY member_id
ORDER BY total_cost DESC
LIMIT 100;


-- QUERY 2: Member risk segmentation based on total cost
-- Business Question: How should we categorize members by risk level?
-- ============================================================================
SELECT 
    CASE 
        WHEN total_cost < 18000 THEN 'Low Risk'
        WHEN total_cost BETWEEN 18000 AND 39000 THEN 'Medium Risk'
        ELSE 'High Risk'
    END AS risk_category,
    COUNT(*) AS member_count,
    SUM(total_cost) AS total_cost,
    AVG(total_cost) AS avg_cost_per_member,
    SUM(total_cost) * 100.0 / (SELECT SUM(total_cost) FROM member_risk_data) AS pct_of_total_costs
FROM member_risk_data
GROUP BY risk_category
ORDER BY avg_cost_per_member DESC;


-- QUERY 3: Top cost-driving diagnoses
-- Business Question: Which medical conditions drive the highest costs?
-- ============================================================================
SELECT 
    diagnosis_code,
    COUNT(*) AS claim_count,
    SUM(claim_cost) AS total_cost,
    AVG(claim_cost) AS avg_cost_per_claim
FROM claim_data
WHERE diagnosis_code IS NOT NULL
GROUP BY diagnosis_code
ORDER BY total_cost DESC
LIMIT 10;


-- QUERY 4: High utilizers - members with 4+ claims
-- Business Question: Who are our frequent utilizers requiring case management?
-- ============================================================================
SELECT 
    m.member_id,
    m.claim_count,
    m.total_cost,
    m.risk_category,
    m.chronic_condition_count
FROM member_risk_data m
WHERE m.claim_count >= 4
ORDER BY m.total_cost DESC;


-- QUERY 5: Chronic condition impact on costs
-- Business Question: How do chronic conditions affect healthcare costs?
-- ============================================================================
SELECT 
    chronic_condition_count,
    COUNT(*) AS member_count,
    AVG(total_cost) AS avg_cost,
    MIN(total_cost) AS min_cost,
    MAX(total_cost) AS max_cost
FROM member_risk_data
GROUP BY chronic_condition_count
ORDER BY chronic_condition_count;


-- QUERY 6: Monthly claim trends (if date data available)
-- Business Question: What are our utilization patterns over time?
-- ============================================================================
SELECT 
    DATE_TRUNC('month', admission_date) AS month,
    COUNT(*) AS claim_count,
    SUM(claim_cost) AS total_cost,
    AVG(claim_cost) AS avg_cost_per_claim
FROM claim_data
WHERE admission_date IS NOT NULL
GROUP BY DATE_TRUNC('month', admission_date)
ORDER BY month;


-- QUERY 7: High-risk members with multiple chronic conditions
-- Business Question: Which high-cost members need disease management programs?
-- ============================================================================
SELECT 
    member_id,
    total_cost,
    claim_count,
    chronic_condition_count,
    risk_category
FROM member_risk_data
WHERE risk_category = 'High Risk'
    AND chronic_condition_count >= 3
ORDER BY total_cost DESC;


-- QUERY 8: Cost per claim by diagnosis
-- Business Question: Which diagnoses have the highest average cost per episode?
-- ============================================================================
SELECT 
    diagnosis_code,
    COUNT(*) AS total_claims,
    AVG(claim_cost) AS avg_cost_per_claim,
    SUM(claim_cost) AS total_cost
FROM claim_data
WHERE diagnosis_code IS NOT NULL
GROUP BY diagnosis_code
HAVING COUNT(*) >= 100  -- Only diagnoses with sufficient volume
ORDER BY avg_cost_per_claim DESC
LIMIT 20;


-- QUERY 9: Member cost distribution analysis
-- Business Question: What percentage of members account for what percentage of costs?
-- ============================================================================
WITH ranked_members AS (
    SELECT 
        member_id,
        total_cost,
        NTILE(10) OVER (ORDER BY total_cost DESC) AS cost_decile
    FROM member_risk_data
)
SELECT 
    cost_decile,
    COUNT(*) AS member_count,
    SUM(total_cost) AS total_cost,
    SUM(total_cost) * 100.0 / (SELECT SUM(total_cost) FROM member_risk_data) AS pct_of_total_costs
FROM ranked_members
GROUP BY cost_decile
ORDER BY cost_decile;


-- QUERY 10: Members at risk for readmission (2+ claims within 30 days)
-- Business Question: Which members should we target for readmission prevention?
-- ============================================================================
SELECT 
    c1.member_id,
    c1.claim_id AS first_claim,
    c2.claim_id AS second_claim,
    c1.admission_date AS first_admission,
    c2.admission_date AS second_admission,
    c2.admission_date - c1.admission_date AS days_between,
    c1.claim_cost + c2.claim_cost AS combined_cost
FROM claim_data c1
JOIN claim_data c2 
    ON c1.member_id = c2.member_id
    AND c1.claim_id < c2.claim_id
WHERE c2.admission_date - c1.admission_date <= 30
ORDER BY combined_cost DESC;

