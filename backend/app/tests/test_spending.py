"""Integration tests for the Spending Analytics endpoints."""
from datetime import date

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def test_spending_requires_auth() -> None:
    assert client.get("/api/v1/spending/summary").status_code == 401


def test_summary_categories_sum_to_total_and_carry_insight() -> None:
    body = client.get("/api/v1/spending/summary", headers=_auth_headers()).json()

    today = date.today()
    assert body["month"] == f"{today.year}-{today.month:02d}"
    assert body["total_spent"] > 0
    assert body["total_income"] > 0

    cat_sum = sum(c["amount"] for c in body["categories"])
    assert abs(cat_sum - body["total_spent"]) < 1.0  # rounding tolerance
    # Percentages are populated and rent is excluded from neither—income/transfer are.
    assert all(c["category"] not in ("income", "transfer") for c in body["categories"])
    assert body["insight"]["summary"]
    assert body["top_merchants"]


def test_summary_has_month_over_month_trend() -> None:
    body = client.get("/api/v1/spending/summary", headers=_auth_headers()).json()
    # Three months are seeded, current month runs hotter → previous month exists.
    assert body["previous_month_spent"] > 0
    assert body["change_pct"] > 0  # current month seeded higher


def test_transactions_paginate_and_filter_by_category() -> None:
    headers = _auth_headers()
    page = client.get(
        "/api/v1/spending/transactions?limit=5", headers=headers
    ).json()
    assert len(page["items"]) == 5
    assert page["total"] >= 5

    dining = client.get(
        "/api/v1/spending/transactions?category=dining", headers=headers
    ).json()
    assert dining["total"] >= 1
    assert all(t["category"] == "dining" for t in dining["items"])


def test_auto_categorization_assigns_known_merchants() -> None:
    txns = client.get(
        "/api/v1/spending/transactions?limit=200", headers=_auth_headers()
    ).json()["items"]
    by_merchant = {t["merchant"]: t["category"] for t in txns}
    assert by_merchant["Swiggy"] == "dining"
    assert by_merchant["BigBasket"] == "groceries"
    assert by_merchant["Airtel Broadband"] == "utilities"
    assert by_merchant["ACME Corp Salary"] == "income"


def test_budgets_report_progress_and_status() -> None:
    budgets = client.get("/api/v1/spending/budgets", headers=_auth_headers()).json()
    cats = {b["category"] for b in budgets}
    assert "dining" in cats
    for b in budgets:
        assert b["spent"] >= 0
        assert b["status"] in ("under", "near", "over")
        assert abs((b["monthly_limit"] - b["spent"]) - b["remaining"]) < 1.0


def test_set_budget_updates_limit_and_recomputes_status() -> None:
    headers = _auth_headers()
    # A tiny limit should push status to "over".
    resp = client.put(
        "/api/v1/spending/budgets/dining",
        json={"monthly_limit": 1.0},
        headers=headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["monthly_limit"] == 1.0
    assert body["status"] == "over"
