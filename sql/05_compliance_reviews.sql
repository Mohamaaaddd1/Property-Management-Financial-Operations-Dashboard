/*
05_compliance_reviews.sql

Purpose:
List unresolved compliance findings and show property manager exception workload.

Assumption:
CSVs are loaded as tables named after each file without the .csv extension.
*/

WITH review_base AS (
    SELECT
        cr.review_id,
        cr.property_id,
        p.address,
        p.borough,
        p.neighborhood,
        p.asset_type,
        pm.property_manager_name,
        cr.month,
        cr.review_type,
        cr.issue_category,
        cr.severity,
        cr.finding_description,
        cr.recommendation,
        cr.status,
        cr.owner,
        CASE cr.severity
            WHEN 'High' THEN 3
            WHEN 'Medium' THEN 2
            WHEN 'Low' THEN 1
            ELSE 0
        END AS severity_rank
    FROM compliance_reviews AS cr
    INNER JOIN source_real_estate_base_properties AS p
        ON cr.property_id = p.property_id
    LEFT JOIN property_managers AS pm
        ON p.property_manager_id = pm.property_manager_id
),

open_findings AS (
    SELECT *
    FROM review_base
    WHERE status <> 'Resolved'
),

manager_workload AS (
    SELECT
        property_manager_name,
        COUNT(*) AS open_finding_count,
        SUM(CASE WHEN severity = 'High' THEN 1 ELSE 0 END) AS high_severity_open_count,
        SUM(CASE WHEN severity = 'Medium' THEN 1 ELSE 0 END) AS medium_severity_open_count,
        SUM(CASE WHEN severity = 'Low' THEN 1 ELSE 0 END) AS low_severity_open_count,
        COUNT(DISTINCT property_id) AS properties_with_open_findings
    FROM open_findings
    GROUP BY property_manager_name
),

property_workload AS (
    SELECT
        property_id,
        COUNT(*) AS property_open_finding_count,
        SUM(CASE WHEN severity = 'High' THEN 1 ELSE 0 END) AS property_high_severity_open_count
    FROM open_findings
    GROUP BY property_id
)

SELECT
    of.review_id,
    of.month,
    of.property_id,
    of.address AS property_address,
    of.borough,
    of.neighborhood,
    of.asset_type,
    of.property_manager_name,
    mw.open_finding_count AS manager_open_finding_count,
    mw.high_severity_open_count AS manager_high_severity_open_count,
    mw.properties_with_open_findings,
    pw.property_open_finding_count,
    pw.property_high_severity_open_count,
    of.owner AS finding_owner,
    of.review_type,
    of.issue_category,
    of.severity,
    of.status,
    of.finding_description,
    of.recommendation,
    CASE
        WHEN of.severity = 'High' AND of.status = 'Open' THEN 'Immediate action'
        WHEN of.severity = 'High' THEN 'High priority follow-up'
        WHEN of.status = 'Open' THEN 'Open item follow-up'
        ELSE 'Continue review'
    END AS recommended_follow_up_priority
FROM open_findings AS of
LEFT JOIN manager_workload AS mw
    ON of.property_manager_name = mw.property_manager_name
LEFT JOIN property_workload AS pw
    ON of.property_id = pw.property_id
ORDER BY
    mw.high_severity_open_count DESC,
    mw.open_finding_count DESC,
    of.severity_rank DESC,
    of.month DESC,
    of.property_id;
