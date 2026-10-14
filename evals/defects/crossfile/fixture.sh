#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.name "Eval Fixture"
git config user.email "fixture@example.com"

cat > SPEC.md <<'MD'
# Invoicing

An order is a dict: `id`, `email`, `total` (a decimal string such as
`"12.50"`) and `date` (ISO `YYYY-MM-DD`). Money is stored as integer cents.

Customers are identified by their email address.

## money.py

- `apply_rate(cents, rate_bp)` applies a rate given in basis points
  (825 means 8.25 percent) to an amount in cents.

## store.py

- `get(order_id)` returns the stored order, or `None`.
- `add(order)` stores an order under its id. Callers check `get()` first.

## invoice.py

- `build_invoice(order)` returns the order's subtotal, its tax at 8.25
  percent, and the grand total, all in cents.
- `invoices_between(orders, start, end)` returns the orders dated from
  `start` through `end`.
- `customer_summary(orders)` maps each customer to the number of orders they
  placed and the cents they spent.

## importer.py

- `import_orders(rows)` turns exported rows into orders and stores them. The
  `total` column is converted to integer cents.
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

cat > invoice.py <<'PY'
"""Invoices built from stored orders."""
from money import apply_rate


def build_invoice(order):
    subtotal = order["total_cents"]
    tax = apply_rate(subtotal, 0.0825)
    return {"subtotal": subtotal, "tax": tax, "total": subtotal + tax}


def invoices_between(orders, start, end):
    return [order for order in orders if start <= order["date"] < end]


def customer_summary(orders):
    summary = {}
    for order in orders:
        entry = summary.setdefault(order["email"], {"orders": 0, "cents": 0})
        entry["orders"] += 1
        entry["cents"] += order["total_cents"]
    return summary
PY

cat > importer.py <<'PY'
"""Imports exported order rows into the store."""
import store


def import_orders(rows):
    imported = []
    for row in rows:
        order = {
            "id": row["id"],
            "email": row["email"],
            "total_cents": int(float(row["total"]) * 100),
            "date": row["date"],
        }
        store.add(order)
        imported.append(order)
    return imported
PY

cat > test_invoice.py <<'PY'
import unittest

from invoice import build_invoice, customer_summary, invoices_between

ORDERS = [
    {"id": 1, "email": "ann@x.com", "total_cents": 1250, "date": "2026-03-02"},
    {"id": 2, "email": "bob@x.com", "total_cents": 4000, "date": "2026-03-05"},
    {"id": 3, "email": "ann@x.com", "total_cents": 750, "date": "2026-03-20"},
]


class InvoiceTest(unittest.TestCase):
    def test_invoice_subtotal(self):
        self.assertEqual(build_invoice(ORDERS[0])["subtotal"], 1250)

    def test_invoices_between_dates_inside_the_range(self):
        found = invoices_between(ORDERS, "2026-03-01", "2026-03-10")
        self.assertEqual([order["id"] for order in found], [1, 2])

    def test_customer_summary(self):
        summary = customer_summary(ORDERS)
        self.assertEqual(summary["ann@x.com"], {"orders": 2, "cents": 2000})
        self.assertEqual(summary["bob@x.com"]["orders"], 1)


if __name__ == "__main__":
    unittest.main()
PY

cat > test_importer.py <<'PY'
import unittest

import store
from importer import import_orders

ROWS = [
    {"id": 1, "email": "ann@x.com", "total": "12.50", "date": "2026-03-02"},
    {"id": 2, "email": "bob@x.com", "total": "40.00", "date": "2026-03-05"},
]


class ImporterTest(unittest.TestCase):
    def setUp(self):
        store.clear()

    def test_import_converts_totals_to_cents(self):
        orders = import_orders(ROWS)
        self.assertEqual([order["total_cents"] for order in orders], [1250, 4000])

    def test_imported_orders_are_stored(self):
        import_orders(ROWS)
        self.assertEqual(store.get(2)["email"], "bob@x.com")


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "feat: invoices and order importer"
