# Data Validation Summary

Validation source: [`notebooks/01_data_validation.ipynb`](../notebooks/01_data_validation.ipynb)

## Executive Summary

The validation notebook loaded 12 CSV datasets from `data/`, covering 69,125 total rows. The validation run completed with 123 PASS checks, 5 WARN findings, and 0 FAIL findings. The dataset is ready for SQL and Python analysis, with warnings documented as expected or review-oriented data characteristics rather than blocking quality issues.

## Datasets Loaded and Row Counts

| Dataset | Rows | Columns |
|---|---:|---:|
| `DOF_Condominium_Comparable_Rental_Income_in_NYC.csv` | 22,073 | 12 |
| `accounts_receivable.csv` | 25,740 | 10 |
| `ai_monthly_summary_inputs.csv` | 12 | 21 |
| `compliance_reviews.csv` | 2,200 | 11 |
| `leasing_pipeline.csv` | 179 | 11 |
| `monthly_financials.csv` | 2,100 | 16 |
| `property_managers.csv` | 10 | 5 |
| `source_real_estate_base_properties.csv` | 175 | 20 |
| `tenants.csv` | 2,145 | 12 |
| `vendor_invoices.csv` | 10,581 | 17 |
| `vendors.csv` | 17 | 4 |
| `work_orders.csv` | 3,893 | 15 |

## Primary Key Checks

All operational primary keys passed uniqueness and non-null validation:

| Dataset | Primary Key |
|---|---|
| `source_real_estate_base_properties.csv` | `property_id` |
| `property_managers.csv` | `property_manager_id` |
| `tenants.csv` | `tenant_id` |
| `vendors.csv` | `vendor_id` |
| `monthly_financials.csv` | `financial_id` |
| `accounts_receivable.csv` | `ar_id` |
| `vendor_invoices.csv` | `invoice_id` |
| `work_orders.csv` | `work_order_id` |
| `compliance_reviews.csv` | `review_id` |
| `leasing_pipeline.csv` | `opportunity_id` |

## Foreign Key Checks

All populated foreign keys resolved cleanly, with no orphaned IDs found. Validated relationships included:

- `property_id` links from tenants, monthly financials, accounts receivable, vendor invoices, work orders, compliance reviews, and leasing pipeline to the property base.
- `tenant_id` links from accounts receivable and populated work order tenant values to tenants.
- `vendor_id` links from vendor invoices and work orders to vendors.
- `property_manager_id` links from the property base to property managers.

## Date Coverage

All configured date fields parsed successfully. Monthly analysis tables covered the full January 2025 through December 2025 period:

- `monthly_financials.csv`
- `accounts_receivable.csv`
- `compliance_reviews.csv`
- `ai_monthly_summary_inputs.csv`

## Missing-Value Findings

Missing values were limited to documented nullable fields:

| Dataset | Nullable Field Findings |
|---|---|
| `DOF_Condominium_Comparable_Rental_Income_in_NYC.csv` | `Year Built`: 73, `Estimated Expense`: 1, `Full Market Value`: 2 |
| `vendor_invoices.csv` | `paid_date`: 320, `gl_code`: 365 |
| `work_orders.csv` | `tenant_id`: 1,362, `closed_date`: 848, `days_to_close`: 848 |

These are consistent with the dataset design: raw source fields may be incomplete, invoices may be unpaid or missing GL coding, and work orders may be open or not tenant-specific.

## Warning Findings

The validation run returned 5 warnings and 0 failures:

- The raw NYC DOF source file has 3 duplicate full rows. The curated property base has no duplicate rows.
- The raw NYC DOF source has documented nullable fields.
- `vendor_invoices.csv` has documented nullable fields for unpaid invoices and missing GL codes.
- `work_orders.csv` has documented nullable fields for open work orders and non-tenant work orders.
- `potential_duplicate_invoice_flag` marks 194 invoice rows for review, while exact duplicate checks by `vendor_id`, `invoice_number`, and `invoice_amount` found 0 exact duplicate rows.

## Potential Duplicate Invoice Flag

The `potential_duplicate_invoice_flag` field is a business review indicator, not proof of an exact duplicate row. It identifies invoices that should be reviewed for potential duplication based on business logic or exception-generation rules. The validation notebook confirmed that the 194 flagged invoice rows are not exact duplicates using the strict triplet of `vendor_id`, `invoice_number`, and `invoice_amount`.

This distinction is important for analysis: dashboards and SQL queries should label these records as potential duplicate invoice review cases, not confirmed duplicate invoices.

## Readiness for SQL and Python Analysis

The dataset is ready for analysis because:

- Schemas and row counts match the documented dataset design.
- Operational primary keys are unique and non-null.
- Core foreign-key relationships join cleanly across properties, tenants, vendors, managers, invoices, work orders, and compliance reviews.
- Monthly tables provide complete 2025 reporting coverage.
- Key business calculations passed validation, including financial variances, NOI, EBITDA, AR outstanding balance, leasing weighted rent, invoice flags, and work order status logic.
- Warning findings are documented and interpretable, so analysts can handle them intentionally in SQL filters, joins, dashboard labels, and Python notebooks.
