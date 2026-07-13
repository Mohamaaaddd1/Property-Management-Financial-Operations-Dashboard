/*
06_monthly_management_report.sql

Purpose:
Create a monthly management report view with portfolio financials,
AR risk, invoice exceptions, work order backlog, compliance findings,
and leasing pipeline metrics.

Assumption:
CSVs are loaded as tables named after each file without the .csv extension.
*/

WITH reporting_months AS (
    SELECT DISTINCT month
    FROM monthly_financials
),

financial_metrics AS (
    SELECT
        month,
        SUM(budget_income) AS portfolio_budget_income,
        SUM(actual_income) AS portfolio_actual_income,
        SUM(income_variance) AS portfolio_income_variance,
        SUM(budget_expenses) AS portfolio_budget_expenses,
        SUM(actual_expenses) AS portfolio_actual_expenses,
        SUM(expense_variance) AS portfolio_expense_variance,
        SUM(net_operating_income) AS portfolio_noi,
        SUM(ebitda) AS portfolio_ebitda,
        AVG(occupancy_rate) AS average_occupancy_rate,
        SUM(management_fee) AS portfolio_management_fee
    FROM monthly_financials
    GROUP BY month
),

ar_metrics AS (
    SELECT
        month,
        SUM(billed_rent) AS billed_rent,
        SUM(amount_paid) AS amount_paid,
        SUM(outstanding_balance) AS ar_outstanding_balance,
        SUM(CASE WHEN collection_priority = 'Critical' THEN 1 ELSE 0 END) AS critical_ar_count,
        SUM(CASE WHEN collection_priority = 'High' THEN 1 ELSE 0 END) AS high_ar_count,
        COUNT(DISTINCT CASE WHEN outstanding_balance > 0 THEN tenant_id END) AS tenants_with_ar_balance
    FROM accounts_receivable
    GROUP BY month
),

invoice_metrics AS (
    SELECT
        SUBSTR(invoice_date, 1, 7) || '-01' AS month,
        COUNT(*) AS invoice_count,
        SUM(invoice_amount) AS invoice_amount,
        SUM(CASE WHEN LOWER(CAST(compliance_flag AS VARCHAR)) IN ('true', '1', 'yes') THEN 1 ELSE 0 END) AS invoice_exception_count,
        SUM(CASE WHEN LOWER(CAST(late_payment_flag AS VARCHAR)) IN ('true', '1', 'yes') THEN 1 ELSE 0 END) AS late_invoice_count,
        SUM(CASE WHEN LOWER(CAST(potential_duplicate_invoice_flag AS VARCHAR)) IN ('true', '1', 'yes') THEN 1 ELSE 0 END) AS potential_duplicate_review_count,
        SUM(CASE WHEN LOWER(CAST(missing_gl_code_flag AS VARCHAR)) IN ('true', '1', 'yes') THEN 1 ELSE 0 END) AS missing_gl_code_count,
        SUM(CASE WHEN approval_status = 'Pending' THEN 1 ELSE 0 END) AS pending_invoice_count,
        SUM(CASE WHEN approval_status = 'Rejected' THEN 1 ELSE 0 END) AS rejected_invoice_count
    FROM vendor_invoices
    GROUP BY SUBSTR(invoice_date, 1, 7) || '-01'
),

work_order_metrics AS (
    SELECT
        SUBSTR(opened_date, 1, 7) || '-01' AS month,
        COUNT(*) AS work_order_count,
        SUM(CASE WHEN status <> 'Closed' THEN 1 ELSE 0 END) AS active_work_order_count,
        SUM(CASE WHEN LOWER(CAST(overdue_flag AS VARCHAR)) IN ('true', '1', 'yes') THEN 1 ELSE 0 END) AS overdue_work_order_count,
        SUM(CASE WHEN priority = 'Critical' THEN 1 ELSE 0 END) AS critical_work_order_count,
        AVG(estimated_cost) AS average_estimated_work_order_cost
    FROM work_orders
    GROUP BY SUBSTR(opened_date, 1, 7) || '-01'
),

compliance_metrics AS (
    SELECT
        month,
        COUNT(*) AS compliance_review_count,
        SUM(CASE WHEN status <> 'Resolved' THEN 1 ELSE 0 END) AS open_compliance_finding_count,
        SUM(CASE WHEN status <> 'Resolved' AND severity = 'High' THEN 1 ELSE 0 END) AS open_high_severity_finding_count
    FROM compliance_reviews
    GROUP BY month
),

leasing_metrics AS (
    SELECT
        SUBSTR(expected_lease_start, 1, 7) || '-01' AS month,
        COUNT(*) AS leasing_opportunity_count,
        SUM(expected_monthly_rent) AS expected_monthly_rent,
        SUM(weighted_monthly_rent) AS weighted_monthly_rent,
        SUM(CASE WHEN stage = 'Closed Won' THEN 1 ELSE 0 END) AS closed_won_count,
        SUM(CASE WHEN stage = 'Closed Lost' THEN 1 ELSE 0 END) AS closed_lost_count
    FROM leasing_pipeline
    GROUP BY SUBSTR(expected_lease_start, 1, 7) || '-01'
)

SELECT
    rm.month,
    ROUND(fm.portfolio_budget_income, 2) AS portfolio_budget_income,
    ROUND(fm.portfolio_actual_income, 2) AS portfolio_actual_income,
    ROUND(fm.portfolio_income_variance, 2) AS portfolio_income_variance,
    ROUND(fm.portfolio_budget_expenses, 2) AS portfolio_budget_expenses,
    ROUND(fm.portfolio_actual_expenses, 2) AS portfolio_actual_expenses,
    ROUND(fm.portfolio_expense_variance, 2) AS portfolio_expense_variance,
    ROUND(fm.portfolio_noi, 2) AS portfolio_noi,
    ROUND(fm.portfolio_ebitda, 2) AS portfolio_ebitda,
    ROUND(fm.average_occupancy_rate, 4) AS average_occupancy_rate,
    ROUND(fm.portfolio_management_fee, 2) AS portfolio_management_fee,
    ROUND(am.billed_rent, 2) AS billed_rent,
    ROUND(am.amount_paid, 2) AS amount_paid,
    ROUND(am.ar_outstanding_balance, 2) AS ar_outstanding_balance,
    am.critical_ar_count,
    am.high_ar_count,
    am.tenants_with_ar_balance,
    im.invoice_count,
    ROUND(im.invoice_amount, 2) AS invoice_amount,
    im.invoice_exception_count,
    im.late_invoice_count,
    im.potential_duplicate_review_count,
    im.missing_gl_code_count,
    im.pending_invoice_count,
    im.rejected_invoice_count,
    wom.work_order_count,
    wom.active_work_order_count,
    wom.overdue_work_order_count,
    wom.critical_work_order_count,
    ROUND(wom.average_estimated_work_order_cost, 2) AS average_estimated_work_order_cost,
    cm.compliance_review_count,
    cm.open_compliance_finding_count,
    cm.open_high_severity_finding_count,
    COALESCE(lm.leasing_opportunity_count, 0) AS leasing_opportunity_count,
    ROUND(COALESCE(lm.expected_monthly_rent, 0), 2) AS expected_monthly_rent,
    ROUND(COALESCE(lm.weighted_monthly_rent, 0), 2) AS weighted_monthly_rent,
    COALESCE(lm.closed_won_count, 0) AS closed_won_count,
    COALESCE(lm.closed_lost_count, 0) AS closed_lost_count,
    CASE
        WHEN cm.open_high_severity_finding_count > 0 THEN 'Compliance and control follow-up'
        WHEN am.critical_ar_count > 0 THEN 'Collections and AR risk'
        WHEN im.invoice_exception_count >= 200 THEN 'Vendor invoice exception review'
        WHEN wom.overdue_work_order_count >= 50 THEN 'Work order SLA backlog'
        WHEN fm.portfolio_income_variance < 0 OR fm.portfolio_expense_variance > 0 THEN 'Budget variance review'
        ELSE 'Routine monthly monitoring'
    END AS primary_management_focus
FROM reporting_months AS rm
LEFT JOIN financial_metrics AS fm
    ON rm.month = fm.month
LEFT JOIN ar_metrics AS am
    ON rm.month = am.month
LEFT JOIN invoice_metrics AS im
    ON rm.month = im.month
LEFT JOIN work_order_metrics AS wom
    ON rm.month = wom.month
LEFT JOIN compliance_metrics AS cm
    ON rm.month = cm.month
LEFT JOIN leasing_metrics AS lm
    ON rm.month = lm.month
ORDER BY rm.month;
