"""Run project SQL analyses and export result CSVs.

Usage from the project root:
    python src/run_sql_exports.py
"""

from __future__ import annotations

import csv
import logging
import sqlite3
from pathlib import Path
from typing import Optional, Tuple


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data"
SQL_DIR = PROJECT_ROOT / "sql"
PROCESSED_DIR = DATA_DIR / "processed"

SQL_EXPORTS = [
    ("01_budget_variance.sql", "budget_variance_results.csv"),
    ("02_ar_aging.sql", "ar_aging_results.csv"),
    ("03_invoice_exceptions.sql", "invoice_exceptions_results.csv"),
    ("04_work_order_backlog.sql", "work_order_backlog_results.csv"),
    ("05_compliance_reviews.sql", "compliance_reviews_results.csv"),
    ("06_monthly_management_report.sql", "monthly_management_report_results.csv"),
]


def configure_logging() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(message)s",
        datefmt="%H:%M:%S",
    )


def quote_identifier(identifier: str) -> str:
    """Safely quote a SQLite table or column name."""
    return f'"{identifier.replace(chr(34), chr(34) + chr(34))}"'


def normalize_csv_value(value: str) -> Optional[str]:
    """Load blank CSV cells as NULL while preserving all other cell text."""
    return None if value == "" else value


def load_csv_to_sqlite(conn: sqlite3.Connection, csv_path: Path) -> Tuple[str, int, int]:
    """Load one CSV into SQLite as a table named after the CSV stem."""
    table_name = csv_path.stem

    with csv_path.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.reader(file)
        try:
            headers = next(reader)
        except StopIteration as exc:
            raise ValueError(f"{csv_path} is empty and cannot be loaded.") from exc

        if not headers:
            raise ValueError(f"{csv_path} does not contain a header row.")

        quoted_table = quote_identifier(table_name)
        quoted_columns = [quote_identifier(column) for column in headers]
        column_definitions = ", ".join(f"{column} TEXT" for column in quoted_columns)

        conn.execute(f"DROP TABLE IF EXISTS {quoted_table}")
        conn.execute(f"CREATE TABLE {quoted_table} ({column_definitions})")

        placeholders = ", ".join("?" for _ in headers)
        insert_sql = (
            f"INSERT INTO {quoted_table} "
            f"({', '.join(quoted_columns)}) "
            f"VALUES ({placeholders})"
        )

        row_count = 0
        for row in reader:
            if len(row) != len(headers):
                raise ValueError(
                    f"{csv_path} row {row_count + 2} has {len(row)} fields; "
                    f"expected {len(headers)}."
                )
            conn.execute(insert_sql, [normalize_csv_value(value) for value in row])
            row_count += 1

    return table_name, row_count, len(headers)


def load_all_csvs(conn: sqlite3.Connection) -> None:
    csv_files = sorted(DATA_DIR.glob("*.csv"))
    if not csv_files:
        raise FileNotFoundError(f"No CSV files found in {DATA_DIR}")

    logging.info("Loading %s CSV files into SQLite", len(csv_files))
    for csv_path in csv_files:
        table_name, row_count, column_count = load_csv_to_sqlite(conn, csv_path)
        logging.info(
            "Loaded %-55s -> table %-45s (%s rows, %s columns)",
            csv_path.relative_to(PROJECT_ROOT),
            table_name,
            f"{row_count:,}",
            column_count,
        )
    conn.commit()


def export_query_result(
    conn: sqlite3.Connection,
    sql_path: Path,
    output_path: Path,
) -> Tuple[int, int]:
    sql = sql_path.read_text(encoding="utf-8")
    cursor = conn.execute(sql)
    columns = [description[0] for description in cursor.description]
    rows = cursor.fetchall()

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(columns)
        writer.writerows(rows)

    return len(rows), len(columns)


def run_sql_exports(conn: sqlite3.Connection) -> None:
    logging.info("Running SQL scripts and exporting results")
    for sql_filename, output_filename in SQL_EXPORTS:
        sql_path = SQL_DIR / sql_filename
        output_path = PROCESSED_DIR / output_filename

        if not sql_path.exists():
            raise FileNotFoundError(f"Required SQL file not found: {sql_path}")

        row_count, column_count = export_query_result(conn, sql_path, output_path)
        logging.info(
            "Exported %-35s -> %-55s (%s rows, %s columns)",
            sql_path.relative_to(PROJECT_ROOT),
            output_path.relative_to(PROJECT_ROOT),
            f"{row_count:,}",
            column_count,
        )


def main() -> None:
    configure_logging()
    logging.info("Starting SQL export pipeline")
    logging.info("Project root: %s", PROJECT_ROOT)

    with sqlite3.connect(":memory:") as conn:
        load_all_csvs(conn)
        run_sql_exports(conn)

    logging.info("SQL export pipeline complete")


if __name__ == "__main__":
    main()
