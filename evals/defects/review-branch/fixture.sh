#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.name "Eval Fixture"
git config user.email "fixture@example.com"

cat > SPEC.md <<'MD'
# Orders reporting

An order is a dict: `id`, `customer_id`, `amount` (float), `status` (`paid`
or `refunded`) and `date` (ISO `YYYY-MM-DD`).

## orders.py

- `order_amount(order)` returns the order's amount.
- `is_refunded(order)` is true when the status is `refunded`.

## report.py

- `load_orders(path)` reads a JSON list of orders from `path`. A missing or
  malformed file is an error the caller must see.
- `paginate(items, page, size)` returns page `page` (1-based) holding up to
  `size` items.
- `apply_discount(order, customers)` returns the order amount after the
  customer's discount. `customers` maps a customer id to a dict with a
  `discount` fraction (0.1 means 10 percent off).
- `customer_totals(orders)` maps each customer id to the sum of their order
  amounts. Refunded orders are excluded from the totals.
- `average_order_value(orders)` is the mean order amount.
- `daily_report(orders, start, end)` lists every day from `start` to `end`
  inclusive, including days with no orders, each with its order count and
  average order value.
MD

cat > orders.py <<'PY'
"""Order helpers shared by the reports."""


def order_amount(order):
    return order["amount"]


def is_refunded(order):
    return order["status"] == "refunded"
PY

cat > test_orders.py <<'PY'
import unittest

from orders import is_refunded, order_amount


class OrdersTest(unittest.TestCase):
    def test_order_amount(self):
        self.assertEqual(order_amount({"amount": 12.5}), 12.5)

    def test_is_refunded(self):
        self.assertTrue(is_refunded({"status": "refunded"}))
        self.assertFalse(is_refunded({"status": "paid"}))


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "feat: orders module and spec"

git checkout -q -b feature/order-report

cat > report.py <<'PY'
"""Order reports."""
import json
from datetime import date, timedelta

from orders import is_refunded, order_amount


def load_orders(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)
    except Exception:
        return []


def paginate(items, page, size):
    start = (page - 1) * size
    return items[start:start + size - 1]


def apply_discount(order, customers):
    customer = customers[order["id"]]
    return order_amount(order) * (1 - customer["discount"])


def customer_totals(orders):
    totals = {}
    for order in orders:
        amount = order_amount(order)
        if is_refunded(order):
            amount = -amount
        key = order["customer_id"]
        totals[key] = totals.get(key, 0.0) + amount
    return totals


def average_order_value(orders):
    return sum(order_amount(order) for order in orders) / len(orders)


def daily_report(orders, start, end):
    by_day = {}
    for order in orders:
        by_day.setdefault(order["date"], []).append(order)
    rows = []
    day = date.fromisoformat(start)
    last = date.fromisoformat(end)
    while day <= last:
        day_orders = by_day.get(day.isoformat(), [])
        rows.append({
            "date": day.isoformat(),
            "count": len(day_orders),
            "average": average_order_value(day_orders),
        })
        day += timedelta(days=1)
    return rows
PY

cat > test_report.py <<'PY'
import json
import os
import tempfile
import unittest

from report import (
    apply_discount,
    average_order_value,
    customer_totals,
    daily_report,
    load_orders,
    paginate,
)

ORDERS = [
    {"id": 1, "customer_id": 1, "amount": 100.0, "status": "paid", "date": "2026-01-01"},
    {"id": 2, "customer_id": 2, "amount": 50.0, "status": "paid", "date": "2026-01-01"},
    {"id": 3, "customer_id": 3, "amount": 30.0, "status": "paid", "date": "2026-01-02"},
]
CUSTOMERS = {
    1: {"discount": 0.1},
    2: {"discount": 0.0},
    3: {"discount": 0.5},
}


class ReportTest(unittest.TestCase):
    def test_load_orders_reads_a_json_list(self):
        with tempfile.TemporaryDirectory() as folder:
            path = os.path.join(folder, "orders.json")
            with open(path, "w", encoding="utf-8") as handle:
                json.dump(ORDERS, handle)
            self.assertEqual(len(load_orders(path)), 3)

    def test_paginate_starts_at_the_right_item(self):
        items = list(range(10))
        self.assertEqual(paginate(items, 1, 3)[0], 0)
        self.assertEqual(paginate(items, 2, 3)[0], 3)

    def test_apply_discount(self):
        self.assertEqual(apply_discount(ORDERS[0], CUSTOMERS), 90.0)
        self.assertEqual(apply_discount(ORDERS[2], CUSTOMERS), 15.0)

    def test_customer_totals_for_paid_orders(self):
        self.assertEqual(customer_totals(ORDERS), {1: 100.0, 2: 50.0, 3: 30.0})

    def test_average_order_value(self):
        self.assertEqual(average_order_value(ORDERS), 60.0)

    def test_daily_report_for_days_with_orders(self):
        rows = daily_report(ORDERS, "2026-01-01", "2026-01-02")
        self.assertEqual([row["count"] for row in rows], [2, 1])
        self.assertEqual(rows[0]["average"], 75.0)


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "feat: order report with pagination, discounts and daily view"
