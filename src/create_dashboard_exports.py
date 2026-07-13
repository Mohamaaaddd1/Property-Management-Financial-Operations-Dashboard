"""Create dashboard-ready CSV exports from processed analysis results.

Run from the project root:
    python src/create_dashboard_exports.py
"""

from __future__ import annotations

import logging
from functools import reduce
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
DASHBOARD_DIR = PROJECT_ROOT / "data" / "dashboard_exports"

INPUT_FILES = {
    "budget": "budget_variance_results.csv",
    "ar": "ar_aging_results.csv",
    "invoice": "invoice_exceptions_results.csv",
    "work_orders": "work_order_backlog_results.csv",
    "compliance": "compliance_reviews_results.csv",
    "monthly": "monthly_management_report_results.csv",
}


def configure_logging() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(message)s",
        datefmt="%H:%M:%S",
    )


def load_processed_csv(file_name: str) -> pd.DataFrame:
    path = PROCESSED_DIR / file_name
    if not path.exists():
        raise FileNotFoundError(f"Processed input not found: {path}")

    df = pd.read_csv(path)
    logging.info("Loaded %-55s (%s rows, %s columns)", path.relative_to(PROJECT_ROOT), f"{len(df):,}", len(df.columns))
    return df


def select_and_rename(df: pd.DataFrame, column_map: dict[str, str]) -> pd.DataFrame:
    missing_columns = [column for column in column_map if column not in df.columns]
    if missing_columns:
        raise KeyError(f"Missing required columns: {missing_columns}")

    return df[list(column_map)].rename(columns=column_map)


def export_dashboard_csv(df: pd.DataFrame, file_name: str) -> None:
    DASHBOARD_DIR.mkdir(parents=True, exist_ok=True)
    output_path = DASHBOARD_DIR / file_name
    df = clean_numeric_precision(df)
    df.to_csv(output_path, index=False)
    logging.info(
        "Exported %-45s (%s rows, %s columns)",
        output_path.relative_to(PROJECT_ROOT),
        f"{len(df):,}",
        len(df.columns),
    )


def clean_numeric_precision(df: pd.DataFrame) -> pd.DataFrame:
    """Round dashboard numeric fields so BI exports do not show float artifacts."""
    output = df.copy()
    integer_terms = [
        "Count",
        "Rank",
        "Score",
        "Properties",
        "Tenants",
        "Months",
        "Work Orders",
        "Findings",
        "Vendors",
    ]
    money_terms = [
        "Income",
        "Expenses",
        "Variance",
        "NOI",
        "EBITDA",
        "Rent",
        "Balance",
        "Amount",
        "Cost",
        "Fee",
    ]

    for column in output.columns:
        if not pd.api.types.is_numeric_dtype(output[column]):
            continue

        if any(term in column for term in integer_terms):
            output[column] = output[column].round(0).astype("Int64")
        elif column.endswith("%"):
            output[column] = output[column].round(1)
        elif "Rate" in column:
            output[column] = output[column].round(4)
        elif "Average Days" in column:
            output[column] = output[column].round(1)
        elif any(term in column for term in money_terms):
            output[column] = output[column].round(2)
        else:
            output[column] = output[column].round(2)

    return output


def create_executive_monthly_kpis(monthly: pd.DataFrame) -> pd.DataFrame:
    column_map = {
        "month": "Month",
        "portfolio_budget_income": "Portfolio Budget Income",
        "portfolio_actual_income": "Portfolio Actual Income",
        "portfolio_income_variance": "Portfolio Income Variance",
        "portfolio_budget_expenses": "Portfolio Budget Expenses",
        "portfolio_actual_expenses": "Portfolio Actual Expenses",
        "portfolio_expense_variance": "Portfolio Expense Variance",
        "portfolio_noi": "Portfolio NOI",
        "portfolio_ebitda": "Portfolio EBITDA",
        "average_occupancy_rate": "Average Occupancy Rate",
        "ar_outstanding_balance": "AR Outstanding Balance",
        "critical_ar_count": "Critical AR Count",
        "high_ar_count": "High AR Count",
        "tenants_with_ar_balance": "Tenants With AR Balance",
        "invoice_count": "Invoice Count",
        "invoice_amount": "Invoice Amount",
        "invoice_exception_count": "Invoice Exception Count",
        "late_invoice_count": "Late Invoice Count",
        "potential_duplicate_review_count": "Potential Duplicate Review Count",
        "missing_gl_code_count": "Missing GL Code Count",
        "pending_invoice_count": "Pending Invoice Count",
        "rejected_invoice_count": "Rejected Invoice Count",
        "work_order_count": "Work Order Count",
        "active_work_order_count": "Active Work Order Count",
        "overdue_work_order_count": "Overdue Work Order Count",
        "critical_work_order_count": "Critical Work Order Count",
        "open_compliance_finding_count": "Open Compliance Finding Count",
        "open_high_severity_finding_count": "Open High Severity Finding Count",
        "leasing_opportunity_count": "Leasing Opportunity Count",
        "weighted_monthly_rent": "Weighted Monthly Rent",
        "primary_management_focus": "Primary Management Focus",
    }
    return select_and_rename(monthly, column_map).sort_values("Month")


def create_property_budget_variance(budget: pd.DataFrame) -> pd.DataFrame:
    column_map = {
        "property_id": "Property ID",
        "property_address": "Property Address",
        "borough": "Borough",
        "neighborhood": "Neighborhood",
        "asset_type": "Asset Type",
        "property_manager_name": "Property Manager",
        "months_reported": "Months Reported",
        "total_budget_income": "Total Budget Income",
        "total_actual_income": "Total Actual Income",
        "total_income_variance": "Total Income Variance",
        "income_budget_status": "Income Budget Status",
        "total_budget_expenses": "Total Budget Expenses",
        "total_actual_expenses": "Total Actual Expenses",
        "total_expense_variance": "Total Expense Variance",
        "expense_budget_status": "Expense Budget Status",
        "total_noi": "Total NOI",
        "total_ebitda": "Total EBITDA",
        "average_occupancy_rate": "Average Occupancy Rate",
        "latest_month": "Latest Month",
        "latest_noi_change": "Latest NOI Change",
        "noi_trend_status": "NOI Trend Status",
        "latest_ebitda_change": "Latest EBITDA Change",
        "ebitda_trend_status": "EBITDA Trend Status",
        "budget_variance_priority": "Budget Variance Priority",
    }
    output = select_and_rename(budget, column_map)
    return output.sort_values(["Budget Variance Priority", "Total Expense Variance"], ascending=[False, False])


def create_ar_risk_by_tenant(ar: pd.DataFrame) -> pd.DataFrame:
    column_map = {
        "property_id": "Property ID",
        "property_address": "Property Address",
        "borough": "Borough",
        "neighborhood": "Neighborhood",
        "property_manager_name": "Property Manager",
        "tenant_id": "Tenant ID",
        "tenant_name": "Tenant Name",
        "tenant_category": "Tenant Category",
        "tenant_status": "Tenant Status",
        "monthly_rent": "Monthly Rent",
        "latest_ar_month": "Latest AR Month",
        "latest_outstanding_balance": "Latest Outstanding Balance",
        "latest_aging_bucket": "Latest Aging Bucket",
        "latest_collection_priority": "Latest Collection Priority",
        "total_outstanding_balance": "Total Outstanding Balance",
        "months_with_balance": "Months With Balance",
        "high_or_critical_months": "High or Critical Months",
        "ar_risk_status": "AR Risk Status",
    }
    output = select_and_rename(ar, column_map)
    return output.sort_values(
        ["Latest Outstanding Balance", "High or Critical Months", "Total Outstanding Balance"],
        ascending=[False, False, False],
    )


def create_invoice_exception_summary(invoice: pd.DataFrame) -> pd.DataFrame:
    column_map = {
        "vendor_id": "Vendor ID",
        "vendor_name": "Vendor Name",
        "default_invoice_category": "Default Invoice Category",
        "invoice_count": "Invoice Count",
        "properties_impacted": "Properties Impacted",
        "total_invoice_amount": "Total Invoice Amount",
        "exception_invoice_count": "Exception Invoice Count",
        "exception_rate_pct": "Exception Rate %",
        "compliance_exception_count": "Compliance Exception Count",
        "late_payment_count": "Late Payment Count",
        "potential_duplicate_review_count": "Potential Duplicate Review Count",
        "missing_gl_code_count": "Missing GL Code Count",
        "pending_approval_count": "Pending Approval Count",
        "rejected_invoice_count": "Rejected Invoice Count",
        "first_invoice_date": "First Invoice Date",
        "latest_invoice_date": "Latest Invoice Date",
        "vendor_exception_status": "Vendor Exception Status",
    }
    output = select_and_rename(invoice, column_map)
    return output.sort_values(["Exception Invoice Count", "Exception Rate %"], ascending=[False, False])


def create_work_order_backlog_summary(work_orders: pd.DataFrame) -> pd.DataFrame:
    column_map = {
        "property_id": "Property ID",
        "property_address": "Property Address",
        "borough": "Borough",
        "neighborhood": "Neighborhood",
        "asset_type": "Asset Type",
        "property_manager_name": "Property Manager",
        "total_work_orders": "Total Work Orders",
        "active_backlog_count": "Active Backlog Count",
        "open_work_orders": "Open Work Orders",
        "in_progress_work_orders": "In Progress Work Orders",
        "closed_work_orders": "Closed Work Orders",
        "overdue_work_orders": "Overdue Work Orders",
        "overdue_active_backlog_count": "Overdue Active Backlog Count",
        "critical_priority_count": "Critical Priority Count",
        "high_priority_count": "High Priority Count",
        "largest_active_backlog_category": "Largest Active Backlog Category",
        "largest_active_backlog_count": "Largest Active Backlog Count",
        "vendors_assigned": "Vendors Assigned",
        "estimated_work_order_cost": "Estimated Work Order Cost",
        "average_days_to_close": "Average Days to Close",
        "latest_opened_date": "Latest Opened Date",
        "backlog_status": "Backlog Status",
    }
    output = select_and_rename(work_orders, column_map)
    return output.sort_values(
        ["Overdue Active Backlog Count", "Active Backlog Count", "Critical Priority Count"],
        ascending=[False, False, False],
    )


def create_compliance_findings_summary(compliance: pd.DataFrame) -> pd.DataFrame:
    column_map = {
        "review_id": "Review ID",
        "month": "Month",
        "property_id": "Property ID",
        "property_address": "Property Address",
        "borough": "Borough",
        "neighborhood": "Neighborhood",
        "asset_type": "Asset Type",
        "property_manager_name": "Property Manager",
        "finding_owner": "Finding Owner",
        "review_type": "Review Type",
        "issue_category": "Issue Category",
        "severity": "Severity",
        "status": "Status",
        "finding_description": "Finding Description",
        "recommendation": "Recommendation",
        "recommended_follow_up_priority": "Recommended Follow-Up Priority",
    }
    output = select_and_rename(compliance, column_map)
    severity_order = {"High": 1, "Medium": 2, "Low": 3}
    output["_severity_sort"] = output["Severity"].map(severity_order).fillna(9)
    output = output.sort_values(["_severity_sort", "Month", "Property Manager"], ascending=[True, False, True])
    return output.drop(columns=["_severity_sort"])


def create_property_manager_workload(
    budget: pd.DataFrame,
    ar: pd.DataFrame,
    work_orders: pd.DataFrame,
    compliance: pd.DataFrame,
) -> pd.DataFrame:
    budget_workload = budget.assign(
        budget_review_property=budget["budget_variance_priority"].eq("Management review recommended").astype(int),
        declining_noi_property=budget["noi_trend_status"].eq("Declining NOI").astype(int),
        declining_ebitda_property=budget["ebitda_trend_status"].eq("Declining EBITDA").astype(int),
    ).groupby("property_manager_name", as_index=False).agg(
        properties_managed=("property_id", "nunique"),
        budget_review_properties=("budget_review_property", "sum"),
        declining_noi_properties=("declining_noi_property", "sum"),
        declining_ebitda_properties=("declining_ebitda_property", "sum"),
        total_income_variance=("total_income_variance", "sum"),
        total_expense_variance=("total_expense_variance", "sum"),
    )

    ar_workload = ar.assign(
        high_or_critical_ar_tenant=ar["ar_risk_status"].isin(["Critical AR risk", "High AR risk"]).astype(int)
    ).groupby("property_manager_name", as_index=False).agg(
        high_or_critical_ar_tenants=("high_or_critical_ar_tenant", "sum"),
        latest_ar_outstanding_balance=("latest_outstanding_balance", "sum"),
        total_ar_outstanding_balance=("total_outstanding_balance", "sum"),
    )

    work_order_workload = work_orders.groupby("property_manager_name", as_index=False).agg(
        active_backlog_count=("active_backlog_count", "sum"),
        overdue_active_backlog_count=("overdue_active_backlog_count", "sum"),
        critical_work_order_count=("critical_priority_count", "sum"),
        high_priority_work_order_count=("high_priority_count", "sum"),
        estimated_work_order_cost=("estimated_work_order_cost", "sum"),
    )

    compliance_workload = compliance.assign(
        high_severity_open_finding=compliance["severity"].eq("High").astype(int),
        immediate_action_finding=compliance["recommended_follow_up_priority"].eq("Immediate action").astype(int),
    ).groupby("property_manager_name", as_index=False).agg(
        open_compliance_findings=("review_id", "count"),
        high_severity_open_findings=("high_severity_open_finding", "sum"),
        immediate_action_findings=("immediate_action_finding", "sum"),
        properties_with_open_findings=("property_id", "nunique"),
    )

    workload_tables = [budget_workload, ar_workload, work_order_workload, compliance_workload]
    workload = reduce(
        lambda left, right: left.merge(right, on="property_manager_name", how="outer"),
        workload_tables,
    )

    numeric_columns = [column for column in workload.columns if column != "property_manager_name"]
    workload[numeric_columns] = workload[numeric_columns].fillna(0)

    workload["exception_workload_score"] = (
        workload["budget_review_properties"]
        + workload["high_or_critical_ar_tenants"]
        + workload["overdue_active_backlog_count"]
        + workload["high_severity_open_findings"]
        + workload["immediate_action_findings"]
    )
    workload["workload_rank"] = workload["exception_workload_score"].rank(method="dense", ascending=False).astype(int)
    workload["workload_tier"] = pd.cut(
        workload["workload_rank"],
        bins=[0, 3, 7, float("inf")],
        labels=["High workload", "Moderate workload", "Standard workload"],
        right=True,
    ).astype(str)

    column_map = {
        "property_manager_name": "Property Manager",
        "workload_rank": "Workload Rank",
        "workload_tier": "Workload Tier",
        "properties_managed": "Properties Managed",
        "budget_review_properties": "Budget Review Properties",
        "declining_noi_properties": "Declining NOI Properties",
        "declining_ebitda_properties": "Declining EBITDA Properties",
        "total_income_variance": "Total Income Variance",
        "total_expense_variance": "Total Expense Variance",
        "high_or_critical_ar_tenants": "High or Critical AR Tenants",
        "latest_ar_outstanding_balance": "Latest AR Outstanding Balance",
        "active_backlog_count": "Active Backlog Count",
        "overdue_active_backlog_count": "Overdue Active Backlog Count",
        "critical_work_order_count": "Critical Work Order Count",
        "high_priority_work_order_count": "High Priority Work Order Count",
        "estimated_work_order_cost": "Estimated Work Order Cost",
        "open_compliance_findings": "Open Compliance Findings",
        "high_severity_open_findings": "High Severity Open Findings",
        "immediate_action_findings": "Immediate Action Findings",
        "properties_with_open_findings": "Properties With Open Findings",
        "exception_workload_score": "Exception Workload Score",
    }
    output = select_and_rename(workload, column_map)
    return output.sort_values(["Workload Rank", "Property Manager"])


def main() -> None:
    configure_logging()
    logging.info("Starting dashboard export creation")
    logging.info("Project root: %s", PROJECT_ROOT)

    budget = load_processed_csv(INPUT_FILES["budget"])
    ar = load_processed_csv(INPUT_FILES["ar"])
    invoice = load_processed_csv(INPUT_FILES["invoice"])
    work_orders = load_processed_csv(INPUT_FILES["work_orders"])
    compliance = load_processed_csv(INPUT_FILES["compliance"])
    monthly = load_processed_csv(INPUT_FILES["monthly"])

    dashboard_exports = {
        "executive_monthly_kpis.csv": create_executive_monthly_kpis(monthly),
        "property_budget_variance.csv": create_property_budget_variance(budget),
        "ar_risk_by_tenant.csv": create_ar_risk_by_tenant(ar),
        "invoice_exception_summary.csv": create_invoice_exception_summary(invoice),
        "work_order_backlog_summary.csv": create_work_order_backlog_summary(work_orders),
        "compliance_findings_summary.csv": create_compliance_findings_summary(compliance),
        "property_manager_workload.csv": create_property_manager_workload(budget, ar, work_orders, compliance),
    }

    for file_name, df in dashboard_exports.items():
        export_dashboard_csv(df, file_name)

    logging.info("Dashboard export creation complete")


if __name__ == "__main__":
    main()
