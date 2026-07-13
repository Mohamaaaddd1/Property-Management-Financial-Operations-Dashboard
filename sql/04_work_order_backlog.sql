/*
04_work_order_backlog.sql

Purpose:
Identify properties with overdue work orders and backlog pressure.

Assumption:
CSVs are loaded as tables named after each file without the .csv extension.
*/

WITH work_order_base AS (
    SELECT
        wo.work_order_id,
        wo.property_id,
        p.address,
        p.borough,
        p.neighborhood,
        p.asset_type,
        pm.property_manager_name,
        wo.tenant_id,
        t.tenant_name,
        wo.opened_date,
        wo.closed_date,
        wo.work_order_category,
        wo.priority,
        wo.status,
        wo.sla_days,
        wo.days_to_close,
        CASE WHEN LOWER(CAST(wo.overdue_flag AS VARCHAR)) IN ('true', '1', 'yes') THEN 1 ELSE 0 END AS is_overdue,
        wo.estimated_cost,
        wo.vendor_id,
        wo.vendor_name
    FROM work_orders AS wo
    INNER JOIN source_real_estate_base_properties AS p
        ON wo.property_id = p.property_id
    LEFT JOIN property_managers AS pm
        ON p.property_manager_id = pm.property_manager_id
    LEFT JOIN tenants AS t
        ON wo.tenant_id = t.tenant_id
),

property_backlog AS (
    SELECT
        property_id,
        address,
        borough,
        neighborhood,
        asset_type,
        property_manager_name,
        COUNT(*) AS total_work_orders,
        SUM(CASE WHEN status = 'Open' THEN 1 ELSE 0 END) AS open_work_orders,
        SUM(CASE WHEN status = 'In Progress' THEN 1 ELSE 0 END) AS in_progress_work_orders,
        SUM(CASE WHEN status = 'Closed' THEN 1 ELSE 0 END) AS closed_work_orders,
        SUM(CASE WHEN status <> 'Closed' THEN 1 ELSE 0 END) AS active_backlog_count,
        SUM(is_overdue) AS overdue_work_orders,
        SUM(CASE WHEN status <> 'Closed' AND is_overdue = 1 THEN 1 ELSE 0 END) AS overdue_active_backlog_count,
        SUM(CASE WHEN priority = 'Critical' THEN 1 ELSE 0 END) AS critical_priority_count,
        SUM(CASE WHEN priority = 'High' THEN 1 ELSE 0 END) AS high_priority_count,
        COUNT(DISTINCT vendor_id) AS vendors_assigned,
        SUM(estimated_cost) AS estimated_work_order_cost,
        AVG(CASE WHEN status = 'Closed' THEN days_to_close END) AS average_days_to_close,
        MAX(opened_date) AS latest_opened_date
    FROM work_order_base
    GROUP BY
        property_id,
        address,
        borough,
        neighborhood,
        asset_type,
        property_manager_name
),

top_backlog_category AS (
    SELECT
        property_id,
        work_order_category,
        COUNT(*) AS category_work_order_count,
        ROW_NUMBER() OVER (
            PARTITION BY property_id
            ORDER BY COUNT(*) DESC, work_order_category
        ) AS category_rank
    FROM work_order_base
    WHERE status <> 'Closed'
    GROUP BY
        property_id,
        work_order_category
)

SELECT
    pb.property_id,
    pb.address AS property_address,
    pb.borough,
    pb.neighborhood,
    pb.asset_type,
    pb.property_manager_name,
    pb.total_work_orders,
    pb.active_backlog_count,
    pb.open_work_orders,
    pb.in_progress_work_orders,
    pb.closed_work_orders,
    pb.overdue_work_orders,
    pb.overdue_active_backlog_count,
    pb.critical_priority_count,
    pb.high_priority_count,
    tbc.work_order_category AS largest_active_backlog_category,
    tbc.category_work_order_count AS largest_active_backlog_count,
    pb.vendors_assigned,
    ROUND(pb.estimated_work_order_cost, 2) AS estimated_work_order_cost,
    ROUND(pb.average_days_to_close, 1) AS average_days_to_close,
    pb.latest_opened_date,
    CASE
        WHEN pb.overdue_active_backlog_count > 0
            OR pb.critical_priority_count > 0
            THEN 'Immediate backlog review'
        WHEN pb.active_backlog_count >= 10
            OR pb.high_priority_count >= 5
            THEN 'Elevated backlog monitoring'
        WHEN pb.active_backlog_count > 0
            THEN 'Routine backlog monitoring'
        ELSE 'No active backlog'
    END AS backlog_status
FROM property_backlog AS pb
LEFT JOIN top_backlog_category AS tbc
    ON pb.property_id = tbc.property_id
    AND tbc.category_rank = 1
ORDER BY
    pb.overdue_active_backlog_count DESC,
    pb.active_backlog_count DESC,
    pb.critical_priority_count DESC,
    pb.estimated_work_order_cost DESC;
