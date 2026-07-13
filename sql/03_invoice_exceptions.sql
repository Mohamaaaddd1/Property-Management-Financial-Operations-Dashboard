/*
03_invoice_exceptions.sql

Purpose:
Identify vendors and invoice categories with the highest exception workload.

Assumption:
CSVs are loaded as tables named after each file without the .csv extension.
*/

WITH invoice_base AS (
    SELECT
        vi.invoice_id,
        vi.property_id,
        vi.vendor_id,
        vi.vendor_name,
        v.default_invoice_category,
        vi.invoice_number,
        vi.invoice_category,
        vi.invoice_date,
        vi.due_date,
        vi.paid_date,
        vi.invoice_amount,
        vi.approval_status,
        vi.gl_code,
        CASE WHEN LOWER(CAST(vi.late_payment_flag AS VARCHAR)) IN ('true', '1', 'yes') THEN 1 ELSE 0 END AS is_late_payment,
        CASE WHEN LOWER(CAST(vi.potential_duplicate_invoice_flag AS VARCHAR)) IN ('true', '1', 'yes') THEN 1 ELSE 0 END AS is_potential_duplicate_review,
        CASE WHEN LOWER(CAST(vi.missing_gl_code_flag AS VARCHAR)) IN ('true', '1', 'yes') THEN 1 ELSE 0 END AS is_missing_gl_code,
        CASE WHEN LOWER(CAST(vi.compliance_flag AS VARCHAR)) IN ('true', '1', 'yes') THEN 1 ELSE 0 END AS is_compliance_exception
    FROM vendor_invoices AS vi
    LEFT JOIN vendors AS v
        ON vi.vendor_id = v.vendor_id
),

invoice_exception_flags AS (
    SELECT
        invoice_base.*,
        CASE WHEN approval_status = 'Pending' THEN 1 ELSE 0 END AS is_pending_approval,
        CASE WHEN approval_status = 'Rejected' THEN 1 ELSE 0 END AS is_rejected,
        CASE
            WHEN is_compliance_exception = 1
                OR is_late_payment = 1
                OR is_potential_duplicate_review = 1
                OR is_missing_gl_code = 1
                OR approval_status IN ('Pending', 'Rejected')
                THEN 1
            ELSE 0
        END AS has_invoice_exception
    FROM invoice_base
),

vendor_exception_summary AS (
    SELECT
        vendor_id,
        vendor_name,
        default_invoice_category,
        COUNT(*) AS invoice_count,
        COUNT(DISTINCT property_id) AS properties_impacted,
        SUM(invoice_amount) AS total_invoice_amount,
        SUM(has_invoice_exception) AS exception_invoice_count,
        SUM(is_compliance_exception) AS compliance_exception_count,
        SUM(is_late_payment) AS late_payment_count,
        SUM(is_potential_duplicate_review) AS potential_duplicate_review_count,
        SUM(is_missing_gl_code) AS missing_gl_code_count,
        SUM(is_pending_approval) AS pending_approval_count,
        SUM(is_rejected) AS rejected_invoice_count,
        MIN(invoice_date) AS first_invoice_date,
        MAX(invoice_date) AS latest_invoice_date
    FROM invoice_exception_flags
    GROUP BY
        vendor_id,
        vendor_name,
        default_invoice_category
)

SELECT
    vendor_id,
    vendor_name,
    default_invoice_category,
    invoice_count,
    properties_impacted,
    ROUND(total_invoice_amount, 2) AS total_invoice_amount,
    exception_invoice_count,
    ROUND(100.0 * exception_invoice_count / NULLIF(invoice_count, 0), 1) AS exception_rate_pct,
    compliance_exception_count,
    late_payment_count,
    potential_duplicate_review_count,
    missing_gl_code_count,
    pending_approval_count,
    rejected_invoice_count,
    first_invoice_date,
    latest_invoice_date,
    CASE
        WHEN exception_invoice_count >= 100
            OR 100.0 * exception_invoice_count / NULLIF(invoice_count, 0) >= 30
            THEN 'High vendor exception workload'
        WHEN exception_invoice_count >= 25
            THEN 'Moderate vendor exception workload'
        ELSE 'Low vendor exception workload'
    END AS vendor_exception_status
FROM vendor_exception_summary
ORDER BY
    exception_invoice_count DESC,
    exception_rate_pct DESC,
    total_invoice_amount DESC;
