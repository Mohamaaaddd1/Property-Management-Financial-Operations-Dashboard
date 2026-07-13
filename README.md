# Property Management Financial Operations & Compliance Analytics

## Executive Summary

This project is a property management analytics portfolio project that turns a real NYC condominium rental-income dataset into a connected operating analytics workflow. It combines SQL, Python, dashboard-ready exports, and responsible AI-assisted reporting to monitor budget variance, AR risk, vendor invoice exceptions, work order backlog, compliance findings, and monthly management KPIs.

The result is a repeatable analyst workflow: validate data, run SQL analyses, export clean dashboard tables, create Python charts, and generate a human-reviewed monthly management summary.

## Business Problem

Property management teams need to connect financial performance with day-to-day operating risk. A monthly review should answer practical questions:

- Which properties are over or under budget?
- Which tenants and properties need AR follow-up?
- Which vendors are creating invoice exceptions?
- Which properties have work order backlog or SLA risk?
- Which compliance findings remain open?
- Which property managers have the highest exception workload?
- What should be included in a monthly client-ready management report?

## Why Real + Synthetic Data

Public property management operations datasets are limited because tenant AR, vendor invoices, work orders, and compliance reviews are usually private. To create a realistic portfolio project without exposing client data, this project uses:

- A real NYC Department of Finance condominium comparable rental-income dataset as the property and income foundation.
- Synthetic connected property-management operations data for tenants, monthly financials, accounts receivable, vendors, invoices, work orders, compliance reviews, leasing pipeline, and AI-ready summary inputs.

This design preserves a real real-estate foundation while safely simulating the operational tables a Property Management Analyst would use in a professional environment.

## Dataset Overview

Core files are stored in [`data/`](data/).

| Dataset | Rows | Purpose |
|---|---:|---|
| `source_real_estate_base_properties.csv` | 175 | Curated real-property foundation with property IDs and manager assignments |
| `property_managers.csv` | 10 | Property manager lookup |
| `tenants.csv` | 2,145 | Synthetic tenant and lease records |
| `vendors.csv` | 17 | Vendor lookup |
| `monthly_financials.csv` | 2,100 | Monthly budget, actuals, NOI, EBITDA, occupancy, and variance metrics |
| `accounts_receivable.csv` | 25,740 | Rent billing, payments, outstanding balances, aging, and collection priority |
| `vendor_invoices.csv` | 10,581 | Invoice approval, GL coding, late-payment, and exception flags |
| `work_orders.csv` | 3,893 | Maintenance backlog, SLA, vendor, cost, status, and overdue flags |
| `compliance_reviews.csv` | 2,200 | Review findings across invoice, financial, and operations exceptions |
| `leasing_pipeline.csv` | 179 | Leasing opportunities and weighted rent |
| `ai_monthly_summary_inputs.csv` | 12 | Monthly KPI inputs for a human-reviewed summary |

## Data Model Overview

The model is built around a property-management operating structure:

- `property_id` connects properties to tenants, financials, AR, invoices, work orders, compliance reviews, and leasing pipeline.
- `tenant_id` connects tenants to AR and tenant-related work orders.
- `vendor_id` connects vendors to invoices and work orders.
- `property_manager_id` connects properties to manager ownership.
- `month` connects recurring monthly financial, AR, compliance, and management-report outputs.

Processed outputs are created in [`data/processed/`](data/processed/), and dashboard-ready exports are created in [`data/dashboard_exports/`](data/dashboard_exports/).

## Tools Used

- SQL for business logic and analysis queries
- SQLite for local SQL execution
- Python for orchestration and exports
- pandas for data loading, aggregation, and validation
- matplotlib for professional charting
- Tableau/Power BI-ready CSV exports for dashboard development
- Responsible AI-assisted reporting using a local rule-based template, with no external API or client data

## Key Analyses

| Analysis | Output |
|---|---|
| Budget variance | Identifies properties over or under budget and flags NOI/EBITDA trend risk |
| AR aging | Ranks tenant AR exposure, aging buckets, and collection priority |
| Vendor invoice exceptions | Summarizes late payments, missing GL codes, approval issues, and potential duplicate review cases |
| Work order backlog | Highlights overdue active backlog, critical work orders, and property-level SLA risk |
| Compliance reviews | Lists open findings and high-severity follow-up items |
| Monthly management KPIs | Combines financial, AR, invoice, work order, compliance, and leasing metrics by month |
| AI-assisted monthly summary | Generates a local, human-reviewed draft summary for monthly reporting |

## Key Findings from Generated Outputs

Latest reporting month: **December 2025**

- Portfolio NOI was **$29.9M** and EBITDA was **$28.2M**, with average occupancy at **93.0%**.
- Actual income trailed budget by **$4.0M**, while expenses exceeded budget by **$1.1M**.
- The December management focus was **Compliance and control follow-up**.
- AR outstanding was **$941.9K**, with **11 critical** and **18 high-priority** AR records.
- Invoice exceptions totaled **241**, representing roughly **27.2%** of invoice volume.
- Vendor exception review included **103 late invoices**, **33 missing GL code items**, and **11 potential duplicate review cases**.
- Work order operations had **66 active work orders** and **58 overdue work orders**.
- Compliance reviews had **98 open findings**, including **31 high-severity open findings**.
- The property manager workload export ranked **Jordan Lee** as the highest exception workload manager in the generated outputs.

## Dashboard Screenshots and Reports

Dashboard screenshots:

### 1. Executive Monthly KPI Overview

![Executive Monthly KPI Overview](dashboards/screenshots/01_Executive%20Monthly%20KPI%20Overview.png)

### 2. Property Budget & Operational Risk

![Property Budget and Operational Risk](dashboards/screenshots/02_Property%20Budget%20%26%20Operational%20Risk.png)

### 3. AR, Vendor Invoices & Compliance Controls

![AR, Vendor Invoices and Compliance Controls](dashboards/screenshots/03_AR%2C%20Vendor%20Invoices%20%26%20Compliance%20Controls.png)

Generated reports:

- [01 Data Validation Summary](reports/01_data_validation_summary.md)
- [02 AI-Assisted Monthly Summary](reports/02_ai_assisted_monthly_summary.md)

## Project Structure

```text
Property_Management_Analytics_Project/
├── data/
│   ├── processed/
│   ├── dashboard_exports/
│   ├── DATA_DICTIONARY.md
│   └── README.md
├── sql/
│   ├── 01_budget_variance.sql
│   ├── 02_ar_aging.sql
│   ├── 03_invoice_exceptions.sql
│   ├── 04_work_order_backlog.sql
│   ├── 05_compliance_reviews.sql
│   └── 06_monthly_management_report.sql
├── notebooks/
│   ├── 01_data_validation.ipynb
│   ├── 02_property_management_analysis.ipynb
│   └── 03_ai_assisted_monthly_summary.ipynb
├── reports/
│   ├── figures/
│   ├── 01_data_validation_summary.md
│   └── 02_ai_assisted_monthly_summary.md
├── src/
│   ├── run_sql_exports.py
│   └── create_dashboard_exports.py
└── README.md
```

## How to Run the Project

Run commands from the project root.

1. Install Python dependencies:

```bash
python3 -m pip install -r requirements.txt
```

2. Validate the source data:

```bash
jupyter notebook notebooks/01_data_validation.ipynb
```

3. Run SQL analyses and export processed results:

```bash
python3 src/run_sql_exports.py
```

4. Create dashboard-ready CSV files for Tableau or Power BI:

```bash
python3 src/create_dashboard_exports.py
```

5. Run the Python analysis notebook and generate charts:

```bash
jupyter notebook notebooks/02_property_management_analysis.ipynb
```

6. Generate the AI-assisted monthly summary:

```bash
jupyter notebook notebooks/03_ai_assisted_monthly_summary.ipynb
```

The core Python scripts use local CSV files and do not modify the original source data.

## Responsible AI Note

The AI-assisted monthly summary is generated locally using a rule-based reporting template and validated project CSV inputs. No external API or client data is used. The narrative is intended as a draft reporting aid and must be reviewed by a property management analyst before any client-facing delivery.

See [`reports/02_ai_assisted_monthly_summary.md`](reports/02_ai_assisted_monthly_summary.md) for the generated example.

## Portfolio Relevance

This project demonstrates practical property management analytics skills aligned to a Property Management Analyst role:

- Translating operational questions into SQL outputs
- Validating connected real estate and operations data
- Building KPI-ready datasets for BI dashboards
- Monitoring budget variance, AR risk, vendor controls, backlog, and compliance workload
- Communicating monthly performance in business-friendly language
- Applying responsible AI as a supervised reporting aid rather than an automated decision-maker
