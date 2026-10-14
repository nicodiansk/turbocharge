#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.name "Eval Fixture"
git config user.email "fixture@example.com"

cat > SPEC.md <<'MD'
# Invoicing

An order is a dict: `id`, `email`, `total_cents` (integer cents) and `date`
(ISO `YYYY-MM-DD`). Exported rows carry `total` instead, a decimal string
such as `"12.50"`. Money is stored as integer cents.

Customers are identified by their email address.

## money.py

- `apply_rate(cents, rate_bp)` applies a rate given in basis points
  (825 means 8.25 percent) to an amount in cents.

## store.py

- `get(order_id)` returns the stored order, or `None`.
- `add(order)` stores an order under its id. Callers check `get()` first.

## Configuration

- `config.py` holds the tax rate (8.25 percent), the export directory and
  the data file path.

## Importing

- `import_orders(rows)` turns exported rows into orders and stores them. The
  `total` column is converted to integer cents.
- `import_file(path)` reads a CSV export and imports its rows.

## Invoices

- `build_invoice(order, code=None)` returns the order's subtotal, its tax at
  8.25 percent, any discount, and the grand total, all in cents.
- `invoices_between(orders, start, end)` returns the orders dated from
  `start` through `end`.
- A discount code stops working on its expiry date: it is valid on every
  day before it.

## Reports

- `customer_summary(orders)` maps each customer to the number of orders they
  placed and the cents they spent.
- Amounts are shown to the user as dollars with two decimals.

## Exporting

- Exports are written inside the export directory (`config.EXPORT_DIR`),
  under a file name the caller supplies.

## Saved data

- Orders are saved to the data file as JSON. A corrupt or unreadable saved
  file is reported to the user.

## Command line

- `cli.main(argv)` runs `import`, `export` or `report`. A failing command
  is logged and its error reaches the caller.
MD

cat > money.py <<'PY'
"""Money helpers. Amounts are integer cents."""


def apply_rate(cents, rate_bp):
    return cents * rate_bp // 10000
PY

cat > store.py <<'PY'
"""In-memory order store. Callers check get() first."""

_ORDERS = {}


def get(order_id):
    return _ORDERS.get(order_id)


def add(order):
    _ORDERS[order["id"]] = order


def clear():
    _ORDERS.clear()
PY

cat > test_money.py <<'PY'
import unittest

from money import apply_rate


class MoneyTest(unittest.TestCase):
    def test_apply_rate_in_basis_points(self):
        self.assertEqual(apply_rate(10000, 825), 825)
        self.assertEqual(apply_rate(2000, 500), 100)


if __name__ == "__main__":
    unittest.main()
PY

cat > test_store.py <<'PY'
import unittest

import store


class StoreTest(unittest.TestCase):
    def setUp(self):
        store.clear()

    def test_get_returns_none_when_missing(self):
        self.assertIsNone(store.get(1))

    def test_add_then_get(self):
        store.add({"id": 1, "email": "a@x.com"})
        self.assertEqual(store.get(1)["email"], "a@x.com")


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "feat: money and store modules and spec"

git checkout -q -b feature/invoices

cat > config.py <<'PY'
"""Settings shared by the invoicing modules."""
import os

TAX_RATE = 0.0825
EXPORT_DIR = os.path.join(os.path.expanduser("~"), "invoice-exports")
DATA_FILE = os.path.join(os.path.expanduser("~"), "invoice-data.json")
CSV_COLUMNS = ("id", "email", "total", "date")
DEFAULT_CURRENCY = "USD"
PY

cat > models.py <<'PY'
"""Order rows and the checks applied to them."""
import re
from datetime import date

REQUIRED_FIELDS = ("id", "email", "total", "date")
EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class RowError(ValueError):
    """An exported row cannot become an order."""


def check_required(row):
    missing = [name for name in REQUIRED_FIELDS if name not in row]
    if missing:
        raise RowError("row is missing " + ", ".join(missing))


def check_email(email):
    if not EMAIL_PATTERN.match(email.strip()):
        raise RowError("bad email: %r" % email)
    return email


def check_date(text):
    try:
        date.fromisoformat(text)
    except ValueError:
        raise RowError("bad date: %r" % text) from None
    return text


def check_total(text):
    if not re.match(r"^\d+(\.\d{1,2})?$", text.strip()):
        raise RowError("bad total: %r" % text)
    return text


def validate_row(row):
    """Return the row when every field is usable, else raise RowError."""
    check_required(row)
    check_email(row["email"])
    check_date(row["date"])
    check_total(row["total"])
    return row


def order_label(order):
    return "#%s <%s>" % (order["id"], order["email"])
PY

cat > persistence.py <<'PY'
"""Saving orders to a JSON file and reading them back."""
import json
import os


def save_orders(path, orders):
    folder = os.path.dirname(path)
    if folder:
        os.makedirs(folder, exist_ok=True)
    temp = path + ".tmp"
    with open(temp, "w", encoding="utf-8") as handle:
        json.dump(list(orders), handle, indent=2, sort_keys=True)
    os.replace(temp, path)


def load_orders(path):
    if not os.path.exists(path):
        return []
    try:
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)
    except Exception:
        return []


def order_count(path):
    return len(load_orders(path))
PY

cat > importer.py <<'PY'
"""Imports exported order rows into the store."""
import csv

import config
import models
import store


def to_cents(text):
    return int(float(text) * 100)


def row_to_order(row):
    models.validate_row(row)
    return {
        "id": int(row["id"]),
        "email": row["email"],
        "total_cents": to_cents(row["total"]),
        "date": row["date"],
    }


def import_orders(rows):
    imported = []
    for row in rows:
        order = row_to_order(row)
        store.add(order)
        imported.append(order)
    return imported


def read_rows(path):
    with open(path, newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        missing = [name for name in config.CSV_COLUMNS if name not in (reader.fieldnames or [])]
        if missing:
            raise models.RowError("export lacks columns: " + ", ".join(missing))
        return list(reader)


def import_file(path):
    return import_orders(read_rows(path))
PY

cat > discounts.py <<'PY'
"""Discount codes."""
from datetime import date

CODES = {
    "SPRING10": {"percent": 10, "expires": "2026-04-01"},
    "LOYAL5": {"percent": 5, "expires": "2027-01-01"},
}


def find_code(code):
    return CODES.get(code)


def is_valid(code, today):
    entry = find_code(code)
    if entry is None:
        return False
    # SPEC: a code stops working on its expiry date, so the bound is exclusive.
    return today < entry["expires"]


def discount_cents(code, subtotal, today):
    if not is_valid(code, today):
        return 0
    return subtotal * CODES[code]["percent"] // 100


def today_iso():
    return date.today().isoformat()
PY

cat > invoice.py <<'PY'
"""Invoices built from stored orders."""
import config
import discounts
from money import apply_rate


def build_invoice(order, code=None, today=None):
    subtotal = order["total_cents"]
    tax = apply_rate(subtotal, config.TAX_RATE)
    discount = 0
    if code is not None:
        discount = discounts.discount_cents(code, subtotal, today or discounts.today_iso())
    return {
        "order_id": order["id"],
        "subtotal": subtotal,
        "tax": tax,
        "discount": discount,
        "total": subtotal + tax - discount,
    }


def invoices_between(orders, start, end):
    return [order for order in orders if start <= order["date"] < end]


def invoice_all(orders, code=None, today=None):
    return [build_invoice(order, code, today) for order in orders]


def grand_total(invoices):
    return sum(invoice["total"] for invoice in invoices)
PY

cat > exporter.py <<'PY'
"""Writes invoices to CSV files in the export directory."""
import csv
import os

import config

HEADER = ("order_id", "subtotal", "tax", "discount", "total")


def export_path(name):
    return os.path.join(config.EXPORT_DIR, name)


def invoice_row(invoice):
    return [invoice[column] for column in HEADER]


def export_invoices(invoices, name):
    path = export_path(name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(HEADER)
        for invoice in invoices:
            writer.writerow(invoice_row(invoice))
    return path
PY

cat > report.py <<'PY'
"""Text reports over orders and invoices."""
from invoice import invoices_between


def format_money(cents):
    return "$%s" % format(cents / 100, ",.2f")


def customer_summary(orders):
    summary = {}
    for order in orders:
        entry = summary.setdefault(order["email"], {"orders": 0, "cents": 0})
        entry["orders"] += 1
        entry["cents"] += order["total_cents"]
    return summary


def summary_lines(orders):
    summary = customer_summary(orders)
    return ["%s: %d orders, %s" % (email, entry["orders"], format_money(entry["cents"]))
            for email, entry in sorted(summary.items())]


def period_report(orders, start, end):
    selected = invoices_between(orders, start, end)
    lines = ["Orders %s to %s: %d" % (start, end, len(selected))]
    lines.extend(summary_lines(selected))
    return lines
PY

cat > cli.py <<'PY'
"""Command line entry point."""
import argparse
import logging

import config
import exporter
import importer
import invoice
import persistence
import report

LOG = logging.getLogger("invoicing")


def build_parser():
    parser = argparse.ArgumentParser(prog="invoicing")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("import").add_argument("path")
    commands.add_parser("export").add_argument("name")
    period = commands.add_parser("report")
    period.add_argument("start")
    period.add_argument("end")
    return parser


def run_import(args):
    orders = importer.import_file(args.path)
    persistence.save_orders(config.DATA_FILE, orders)
    return ["imported %d orders" % len(orders)]


def run_export(args):
    orders = persistence.load_orders(config.DATA_FILE)
    path = exporter.export_invoices(invoice.invoice_all(orders), args.name)
    return ["wrote " + path]


def run_report(args):
    orders = persistence.load_orders(config.DATA_FILE)
    return report.period_report(orders, args.start, args.end)


COMMANDS = {"import": run_import, "export": run_export, "report": run_report}


def main(argv):
    args = build_parser().parse_args(argv)
    try:
        lines = COMMANDS[args.command](args)
    except Exception:
        LOG.exception("command %s failed", args.command)
        raise
    return lines
PY

cat > test_models.py <<'PY'
import unittest

import models

ROW = {"id": "1", "email": "ann@x.com", "total": "12.50", "date": "2026-03-02"}


class ModelsTest(unittest.TestCase):
    def test_valid_row_passes(self):
        self.assertIs(models.validate_row(ROW), ROW)

    def test_missing_field_is_reported(self):
        with self.assertRaises(models.RowError):
            models.validate_row({"id": "1"})

    def test_bad_email(self):
        with self.assertRaises(models.RowError):
            models.check_email("not-an-email")

    def test_bad_date(self):
        with self.assertRaises(models.RowError):
            models.check_date("2026-13-40")

    def test_bad_total(self):
        with self.assertRaises(models.RowError):
            models.check_total("twelve")

    def test_order_label(self):
        self.assertEqual(models.order_label({"id": 4, "email": "a@x.com"}), "#4 <a@x.com>")


if __name__ == "__main__":
    unittest.main()
PY

cat > test_persistence.py <<'PY'
import os
import tempfile
import unittest

import persistence


class PersistenceTest(unittest.TestCase):
    def test_save_then_load(self):
        with tempfile.TemporaryDirectory() as folder:
            path = os.path.join(folder, "data.json")
            persistence.save_orders(path, [{"id": 1}])
            self.assertEqual(persistence.load_orders(path), [{"id": 1}])
            self.assertEqual(persistence.order_count(path), 1)

    def test_missing_file_has_no_orders(self):
        with tempfile.TemporaryDirectory() as folder:
            self.assertEqual(persistence.load_orders(os.path.join(folder, "none.json")), [])


if __name__ == "__main__":
    unittest.main()
PY

cat > test_importer.py <<'PY'
import os
import tempfile
import unittest

import importer
import models
import store

ROWS = [
    {"id": "1", "email": "ann@x.com", "total": "12.50", "date": "2026-03-02"},
    {"id": "2", "email": "bob@x.com", "total": "40.00", "date": "2026-03-05"},
]


class ImporterTest(unittest.TestCase):
    def setUp(self):
        store.clear()

    def test_import_converts_totals_to_cents(self):
        orders = importer.import_orders(ROWS)
        self.assertEqual([order["total_cents"] for order in orders], [1250, 4000])

    def test_imported_orders_are_stored(self):
        importer.import_orders(ROWS)
        self.assertEqual(store.get(2)["email"], "bob@x.com")

    def test_invalid_row_is_rejected(self):
        with self.assertRaises(models.RowError):
            importer.import_orders([{"id": "3", "email": "bad", "total": "1.00", "date": "2026-03-02"}])

    def test_import_file_reads_a_csv_export(self):
        with tempfile.TemporaryDirectory() as folder:
            path = os.path.join(folder, "orders.csv")
            with open(path, "w", encoding="utf-8") as handle:
                handle.write("id,email,total,date\n7,cy@x.com,5.00,2026-03-09\n")
            self.assertEqual(importer.import_file(path)[0]["total_cents"], 500)

    def test_export_without_columns_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            path = os.path.join(folder, "orders.csv")
            with open(path, "w", encoding="utf-8") as handle:
                handle.write("id,email\n7,cy@x.com\n")
            with self.assertRaises(models.RowError):
                importer.read_rows(path)


if __name__ == "__main__":
    unittest.main()
PY

cat > test_discounts.py <<'PY'
import unittest

import discounts


class DiscountsTest(unittest.TestCase):
    def test_code_is_valid_before_its_expiry_date(self):
        self.assertTrue(discounts.is_valid("SPRING10", "2026-03-31"))

    def test_code_stops_working_on_its_expiry_date(self):
        self.assertFalse(discounts.is_valid("SPRING10", "2026-04-01"))

    def test_unknown_code_is_not_valid(self):
        self.assertFalse(discounts.is_valid("NOPE", "2026-01-01"))

    def test_discount_amount(self):
        self.assertEqual(discounts.discount_cents("SPRING10", 2000, "2026-03-01"), 200)
        self.assertEqual(discounts.discount_cents("SPRING10", 2000, "2026-04-02"), 0)


if __name__ == "__main__":
    unittest.main()
PY

cat > test_invoice.py <<'PY'
import unittest

import invoice

ORDERS = [
    {"id": 1, "email": "ann@x.com", "total_cents": 1250, "date": "2026-03-02"},
    {"id": 2, "email": "bob@x.com", "total_cents": 4000, "date": "2026-03-05"},
    {"id": 3, "email": "ann@x.com", "total_cents": 750, "date": "2026-03-20"},
]


class InvoiceTest(unittest.TestCase):
    def test_invoice_subtotal(self):
        self.assertEqual(invoice.build_invoice(ORDERS[0])["subtotal"], 1250)

    def test_invoice_applies_a_valid_code(self):
        built = invoice.build_invoice(ORDERS[1], "SPRING10", "2026-03-10")
        self.assertEqual(built["discount"], 400)

    def test_invoices_between_dates_inside_the_range(self):
        found = invoice.invoices_between(ORDERS, "2026-03-01", "2026-03-10")
        self.assertEqual([order["id"] for order in found], [1, 2])

    def test_invoice_all_builds_one_per_order(self):
        built = invoice.invoice_all(ORDERS)
        self.assertEqual([item["order_id"] for item in built], [1, 2, 3])
        self.assertEqual(invoice.grand_total([{"total": 5}, {"total": 7}]), 12)


if __name__ == "__main__":
    unittest.main()
PY

cat > test_exporter.py <<'PY'
import csv
import os
import tempfile
import unittest

import config
import exporter

INVOICES = [{"order_id": 1, "subtotal": 1250, "tax": 0, "discount": 0, "total": 1250}]


class ExporterTest(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.saved = config.EXPORT_DIR
        config.EXPORT_DIR = self.folder.name

    def tearDown(self):
        config.EXPORT_DIR = self.saved
        self.folder.cleanup()

    def test_export_writes_a_csv_with_a_header(self):
        path = exporter.export_invoices(INVOICES, "march.csv")
        with open(path, newline="", encoding="utf-8") as handle:
            rows = list(csv.reader(handle))
        self.assertEqual(rows[0], list(exporter.HEADER))
        self.assertEqual(rows[1][0], "1")

    def test_export_lands_in_the_export_directory(self):
        path = exporter.export_invoices(INVOICES, "march.csv")
        self.assertEqual(os.path.dirname(path), self.folder.name)


if __name__ == "__main__":
    unittest.main()
PY

cat > test_report.py <<'PY'
import unittest

import report

ORDERS = [
    {"id": 1, "email": "ann@x.com", "total_cents": 1250, "date": "2026-03-02"},
    {"id": 2, "email": "bob@x.com", "total_cents": 4000, "date": "2026-03-05"},
    {"id": 3, "email": "ann@x.com", "total_cents": 750, "date": "2026-03-20"},
]


class ReportTest(unittest.TestCase):
    def test_customer_summary(self):
        summary = report.customer_summary(ORDERS)
        self.assertEqual(summary["ann@x.com"], {"orders": 2, "cents": 2000})
        self.assertEqual(summary["bob@x.com"]["orders"], 1)

    def test_format_money_shows_dollars_with_two_decimals(self):
        self.assertEqual(report.format_money(1999), "$19.99")
        self.assertEqual(report.format_money(123456), "$1,234.56")
        self.assertEqual(report.format_money(5), "$0.05")

    def test_period_report_lists_customers(self):
        lines = report.period_report(ORDERS, "2026-03-01", "2026-03-10")
        self.assertEqual(lines[0], "Orders 2026-03-01 to 2026-03-10: 2")
        self.assertIn("ann@x.com: 1 orders, $12.50", lines)


if __name__ == "__main__":
    unittest.main()
PY

cat > test_cli.py <<'PY'
import os
import tempfile
import unittest

import cli
import config
import models
import store


class CliTest(unittest.TestCase):
    def setUp(self):
        store.clear()
        self.folder = tempfile.TemporaryDirectory()
        self.saved = (config.DATA_FILE, config.EXPORT_DIR)
        config.DATA_FILE = os.path.join(self.folder.name, "data.json")
        config.EXPORT_DIR = os.path.join(self.folder.name, "out")
        self.csv = os.path.join(self.folder.name, "orders.csv")
        with open(self.csv, "w", encoding="utf-8") as handle:
            handle.write("id,email,total,date\n1,ann@x.com,12.50,2026-03-02\n")

    def tearDown(self):
        config.DATA_FILE, config.EXPORT_DIR = self.saved
        self.folder.cleanup()

    def test_import_then_report(self):
        self.assertEqual(cli.main(["import", self.csv]), ["imported 1 orders"])
        lines = cli.main(["report", "2026-03-01", "2026-03-31"])
        self.assertIn("ann@x.com: 1 orders, $12.50", lines)

    def test_import_then_export(self):
        cli.main(["import", self.csv])
        lines = cli.main(["export", "march.csv"])
        self.assertTrue(lines[0].endswith("march.csv"))

    def test_a_failing_command_is_logged_and_reaches_the_caller(self):
        with self.assertLogs("invoicing", level="ERROR"):
            with self.assertRaises(models.RowError):
                cli.main(["import", self._bad_csv()])

    def _bad_csv(self):
        path = os.path.join(self.folder.name, "bad.csv")
        with open(path, "w", encoding="utf-8") as handle:
            handle.write("id,email,total,date\n1,nope,12.50,2026-03-02\n")
        return path


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "feat: invoices, importer, exporter, reports and command line"
