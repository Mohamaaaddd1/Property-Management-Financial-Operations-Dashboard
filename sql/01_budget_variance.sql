/*
01_budget_variance.sql

Purpose:
Identify properties that are over or under budget and flag properties with
declining NOI or EBITDA in the latest reporting month.

Assumption:
CSVs are loaded as tables named after each file without the .csv extension.
*/

WITH property_financials AS (
    SELECT
        mf.property_id,
        p.address,
        p.borough,
        p.neighborhood,
        p.asset_type,
        pm.property_manager_name,
        mf.month,
        mf.budget_income,
        mf.actual_income,
        mf.income_variance,
        mf.income_variance_pct,
        mf.budget_expenses,
        mf.actual_expenses,
        mf.expense_variance,
        mf.expense_variance_pct,
        mf.net_operating_income,
        mf.ebitda,
        mf.occupancy_rate,
        mf.management_fee
    FROM monthly_financials AS mf
    INNER JOIN source_real_estate_base_properties AS p
        ON mf.property_id = p.property_id
    LEFT JOIN property_managers AS pm
        ON p.property_manager_id = pm.property_manager_id
),

monthly_trends AS (
    SELECT
        property_financials.*,
        LAG(net_operating_income) OVER (
            PARTITION BY property_id
            ORDER BY month
        ) AS prior_month_noi,
        LAG(ebitda) OVER (
            PARTITION BY property_id
            ORDER BY month
        ) AS prior_month_ebitda
    FROM property_financials
),

latest_month AS (
    SELECT MAX(month) AS month
    FROM monthly_financials
),

annual_totals AS (
    SELECT
        property_id,
        address,
        borough,
        neighborhood,
        asset_type,
        property_manager_name,
        COUNT(DISTINCT month) AS months_reported,
        SUM(budget_income) AS total_budget_income,
        SUM(actual_income) AS total_actual_income,
        SUM(income_variance) AS total_income_variance,
        SUM(budget_expenses) AS total_budget_expenses,
        SUM(actual_expenses) AS total_actual_expenses,
        SUM(expense_variance) AS total_expense_variance,
        SUM(net_operating_income) AS total_noi,
        SUM(ebitda) AS total_ebitda,
        AVG(occupancy_rate) AS average_occupancy_rate
    FROM property_financials
    GROUP BY
        property_id,
        address,
        borough,
        neighborhood,
        asset_type,
        property_manager_name
),

latest_property_status AS (
    SELECT
        mt.property_id,
        mt.month AS latest_month,
        mt.income_variance AS latest_income_variance,
        mt.income_variance_pct AS latest_income_variance_pct,
        mt.expense_variance AS latest_expense_variance,
        mt.expense_variance_pct AS latest_expense_variance_pct,
        mt.net_operating_income AS latest_noi,
        mt.prior_month_noi,
        mt.net_operating_income - mt.prior_month_noi AS latest_noi_change,
        mt.ebitda AS latest_ebitda,
        mt.prior_month_ebitda,
        mt.ebitda - mt.prior_month_ebitda AS latest_ebitda_change,
        mt.occupancy_rate AS latest_occupancy_rate
    FROM monthly_trends AS mt
    INNER JOIN latest_month AS lm
        ON mt.month = lm.month
)

SELECT
    at.property_id,
    at.address AS property_address,
    at.borough,
    at.neighborhood,
    at.asset_type,
    at.property_manager_name,
    at.months_reported,
    ROUND(at.total_budget_income, 2) AS total_budget_income,
    ROUND(at.total_actual_income, 2) AS total_actual_income,
    ROUND(at.total_income_variance, 2) AS total_income_variance,
    CASE
        WHEN at.total_income_variance < 0 THEN 'Under income budget'
        WHEN at.total_income_variance > 0 THEN 'Over income budget'
        ELSE 'On income budget'
    END AS income_budget_status,
    ROUND(at.total_budget_expenses, 2) AS total_budget_expenses,
    ROUND(at.total_actual_expenses, 2) AS total_actual_expenses,
    ROUND(at.total_expense_variance, 2) AS total_expense_variance,
    CASE
        WHEN at.total_expense_variance > 0 THEN 'Over expense budget'
        WHEN at.total_expense_variance < 0 THEN 'Under expense budget'
        ELSE 'On expense budget'
    END AS expense_budget_status,
    ROUND(at.total_noi, 2) AS total_noi,
    ROUND(at.total_ebitda, 2) AS total_ebitda,
    ROUND(at.average_occupancy_rate, 4) AS average_occupancy_rate,
    lps.latest_month,
    ROUND(lps.latest_income_variance, 2) AS latest_income_variance,
    ROUND(lps.latest_income_variance_pct, 4) AS latest_income_variance_pct,
    ROUND(lps.latest_expense_variance, 2) AS latest_expense_variance,
    ROUND(lps.latest_expense_variance_pct, 4) AS latest_expense_variance_pct,
    ROUND(lps.latest_noi, 2) AS latest_noi,
    ROUND(lps.prior_month_noi, 2) AS prior_month_noi,
    ROUND(lps.latest_noi_change, 2) AS latest_noi_change,
    CASE
        WHEN lps.latest_noi_change < 0 THEN 'Declining NOI'
        WHEN lps.latest_noi_change > 0 THEN 'Improving NOI'
        ELSE 'Flat NOI'
    END AS noi_trend_status,
    ROUND(lps.latest_ebitda, 2) AS latest_ebitda,
    ROUND(lps.prior_month_ebitda, 2) AS prior_month_ebitda,
    ROUND(lps.latest_ebitda_change, 2) AS latest_ebitda_change,
    CASE
        WHEN lps.latest_ebitda_change < 0 THEN 'Declining EBITDA'
        WHEN lps.latest_ebitda_change > 0 THEN 'Improving EBITDA'
        ELSE 'Flat EBITDA'
    END AS ebitda_trend_status,
    CASE
        WHEN at.total_income_variance < 0
            OR at.total_expense_variance > 0
            OR lps.latest_noi_change < 0
            OR lps.latest_ebitda_change < 0
            THEN 'Management review recommended'
        ELSE 'Performing within expected range'
    END AS budget_variance_priority
FROM annual_totals AS at
INNER JOIN latest_property_status AS lps
    ON at.property_id = lps.property_id
ORDER BY
    budget_variance_priority DESC,
    at.total_expense_variance DESC,
    at.total_income_variance ASC;
