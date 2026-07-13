/*
02_ar_aging.sql

Purpose:
Identify tenants and properties with the highest accounts receivable risk.

Assumption:
CSVs are loaded as tables named after each file without the .csv extension.
*/

WITH ar_base AS (
    SELECT
        ar.ar_id,
        ar.property_id,
        p.address,
        p.borough,
        p.neighborhood,
        pm.property_manager_name,
        ar.tenant_id,
        t.tenant_name,
        t.tenant_category,
        t.tenant_status,
        t.monthly_rent,
        ar.month,
        ar.billed_rent,
        ar.amount_paid,
        ar.outstanding_balance,
        ar.aging_bucket,
        ar.collection_priority,
        CASE ar.aging_bucket
            WHEN 'Current' THEN 1
            WHEN '1-30' THEN 2
            WHEN '31-60' THEN 3
            WHEN '61-90' THEN 4
            WHEN '90+' THEN 5
            ELSE 0
        END AS aging_bucket_rank,
        CASE ar.collection_priority
            WHEN 'Low' THEN 1
            WHEN 'Medium' THEN 2
            WHEN 'High' THEN 3
            WHEN 'Critical' THEN 4
            ELSE 0
        END AS collection_priority_rank
    FROM accounts_receivable AS ar
    INNER JOIN tenants AS t
        ON ar.tenant_id = t.tenant_id
    INNER JOIN source_real_estate_base_properties AS p
        ON ar.property_id = p.property_id
    LEFT JOIN property_managers AS pm
        ON p.property_manager_id = pm.property_manager_id
),

latest_month AS (
    SELECT MAX(month) AS month
    FROM accounts_receivable
),

tenant_ar_summary AS (
    SELECT
        property_id,
        address,
        borough,
        neighborhood,
        property_manager_name,
        tenant_id,
        tenant_name,
        tenant_category,
        tenant_status,
        monthly_rent,
        SUM(billed_rent) AS total_billed_rent,
        SUM(amount_paid) AS total_amount_paid,
        SUM(outstanding_balance) AS total_outstanding_balance,
        COUNT(DISTINCT CASE WHEN outstanding_balance > 0 THEN month END) AS months_with_balance,
        SUM(CASE WHEN collection_priority IN ('High', 'Critical') THEN 1 ELSE 0 END) AS high_or_critical_months,
        MAX(aging_bucket_rank) AS worst_aging_bucket_rank,
        MAX(collection_priority_rank) AS worst_collection_priority_rank
    FROM ar_base
    GROUP BY
        property_id,
        address,
        borough,
        neighborhood,
        property_manager_name,
        tenant_id,
        tenant_name,
        tenant_category,
        tenant_status,
        monthly_rent
),

latest_tenant_ar AS (
    SELECT
        ab.property_id,
        ab.tenant_id,
        ab.month AS latest_ar_month,
        ab.outstanding_balance AS latest_outstanding_balance,
        ab.aging_bucket AS latest_aging_bucket,
        ab.collection_priority AS latest_collection_priority
    FROM ar_base AS ab
    INNER JOIN latest_month AS lm
        ON ab.month = lm.month
)

SELECT
    tas.property_id,
    tas.address AS property_address,
    tas.borough,
    tas.neighborhood,
    tas.property_manager_name,
    tas.tenant_id,
    tas.tenant_name,
    tas.tenant_category,
    tas.tenant_status,
    ROUND(tas.monthly_rent, 2) AS monthly_rent,
    lta.latest_ar_month,
    ROUND(lta.latest_outstanding_balance, 2) AS latest_outstanding_balance,
    lta.latest_aging_bucket,
    lta.latest_collection_priority,
    ROUND(tas.total_billed_rent, 2) AS total_billed_rent,
    ROUND(tas.total_amount_paid, 2) AS total_amount_paid,
    ROUND(tas.total_outstanding_balance, 2) AS total_outstanding_balance,
    tas.months_with_balance,
    tas.high_or_critical_months,
    CASE
        WHEN lta.latest_collection_priority = 'Critical'
            OR lta.latest_aging_bucket = '90+'
            OR tas.high_or_critical_months >= 3
            THEN 'Critical AR risk'
        WHEN lta.latest_collection_priority = 'High'
            OR tas.months_with_balance >= 3
            THEN 'High AR risk'
        WHEN lta.latest_outstanding_balance > 0
            THEN 'Monitor'
        ELSE 'Current'
    END AS ar_risk_status
FROM tenant_ar_summary AS tas
INNER JOIN latest_tenant_ar AS lta
    ON tas.property_id = lta.property_id
    AND tas.tenant_id = lta.tenant_id
ORDER BY
    CASE
        WHEN ar_risk_status = 'Critical AR risk' THEN 1
        WHEN ar_risk_status = 'High AR risk' THEN 2
        WHEN ar_risk_status = 'Monitor' THEN 3
        ELSE 4
    END,
    lta.latest_outstanding_balance DESC,
    tas.total_outstanding_balance DESC;
