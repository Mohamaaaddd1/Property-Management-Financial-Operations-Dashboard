# Property Management Synthetic Dataset

## Purpose
This dataset package supports a portfolio project aligned to a Property Management Analyst workflow: monthly financial reporting, budget variance, vendor invoice review, accounts receivable aging, work order monitoring, leasing pipeline reporting, and compliance exception review.

## Source Foundation
`source_real_estate_base_properties.csv` is derived from the uploaded NYC DOF Condominium Comparable Rental Income CSV. It preserves real property-level fields including address, neighborhood, BBL, total units, gross square feet, estimated income, estimated expense, NOI, market value, and report year.

All other operational tables are synthetic and connect back to the real estate property base.

## Core Join Keys
- `property_id`: joins every operational table to the property base.
- `tenant_id`: joins tenant records to AR and tenant-request work orders.
- `vendor_id`: joins vendors to invoices and work orders.
- `property_manager_id`: joins properties to assigned managers.
- `month`: joins monthly reporting tables.

## Files
| File | Rows | Description |
|---|---:|---|
| source_real_estate_base_properties.csv | 175 | Real-property foundation from NYC DOF data with synthetic portfolio assignments. |
| property_managers.csv | 10 | Synthetic manager lookup table. |
| tenants.csv | 2,145 | Synthetic tenant/lease records linked to properties. |
| vendors.csv | 17 | Synthetic vendor master. |
| monthly_financials.csv | 2,100 | Synthetic monthly budget vs actual income/expense, NOI, EBITDA, occupancy, and variance metrics. |
| accounts_receivable.csv | 25,740 | Synthetic rent billing, payments, outstanding balances, aging buckets, and collection priority. |
| vendor_invoices.csv | 10,581 | Synthetic invoice records with approval, GL coding, late-payment, potential-duplicate review, and missing-code flags. |
| work_orders.csv | 3,893 | Synthetic maintenance/work order records with SLA, status, vendor, cost, and overdue flag. |
| compliance_reviews.csv | 2,200 | Synthetic review findings generated from invoice, financial variance, and work order exceptions. |
| leasing_pipeline.csv | 179 | Synthetic leasing/renewal opportunities with stage, probability, expected rent, and weighted rent. |
| ai_monthly_summary_inputs.csv | 12 | Monthly aggregates for a human-reviewed AI reporting assistant. |

## Business Questions
1. Which properties missed income or expense budget?
2. Which properties and tenants drive AR risk?
3. Which vendors or categories create the most invoice exceptions?
4. Which properties have SLA/work order backlog risk?
5. What compliance findings remain open by severity?
6. Which property managers have the heaviest exception workload?
7. What is the monthly portfolio EBITDA/NOI trend?
8. What should be included in a human-reviewed AI monthly summary?

## GitHub Disclosure
This project uses a real public real estate dataset as the property/income foundation and synthetic connected operational tables to simulate property management workflows that are not usually available in public datasets. Synthetic tables are clearly labeled with `synthetic_record = True` and are intended for portfolio demonstration only.
