"""Integration tests for the Notifications endpoints.

Note: the in-memory store is a process-wide singleton, so these tests run in a
deliberate order — read-only checks first, then the mutating ones.
"""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def test_notifications_require_auth() -> None:
    assert client.get("/api/v1/notifications").status_code == 401


def test_list_returns_items_and_unread_count() -> None:
    body = client.get("/api/v1/notifications", headers=_auth_headers()).json()
    assert body["total"] >= 5
    assert body["unread_count"] >= 1
    titles = {n["title"] for n in body["items"]}
    assert "Unusual transaction flagged" in titles
    # Sorted most-recent first.
    assert body["items"][0]["category"] in (
        "security", "alert", "reminder", "insight", "goal", "transaction", "promo"
    )


def test_unread_only_filter_returns_only_unread() -> None:
    body = client.get(
        "/api/v1/notifications?unread_only=true", headers=_auth_headers()
    ).json()
    assert body["items"]
    assert all(n["read"] is False for n in body["items"])


def test_unread_count_endpoint_matches_list() -> None:
    headers = _auth_headers()
    list_count = client.get("/api/v1/notifications", headers=headers).json()["unread_count"]
    endpoint_count = client.get(
        "/api/v1/notifications/unread-count", headers=headers
    ).json()["count"]
    assert list_count == endpoint_count


def test_mark_one_read_decrements_unread() -> None:
    headers = _auth_headers()
    unread = client.get(
        "/api/v1/notifications?unread_only=true", headers=headers
    ).json()
    before = unread["unread_count"]
    target = unread["items"][0]["id"]

    resp = client.post(f"/api/v1/notifications/{target}/read", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["read"] is True

    after = client.get(
        "/api/v1/notifications/unread-count", headers=headers
    ).json()["count"]
    assert after == before - 1


def test_mark_unknown_notification_is_404() -> None:
    resp = client.post("/api/v1/notifications/ntf_missing/read", headers=_auth_headers())
    assert resp.status_code == 404


def test_mark_all_read_zeroes_the_count() -> None:
    headers = _auth_headers()
    client.post("/api/v1/notifications/read-all", headers=headers)
    count = client.get(
        "/api/v1/notifications/unread-count", headers=headers
    ).json()["count"]
    assert count == 0
    # A second call has nothing left to update.
    again = client.post("/api/v1/notifications/read-all", headers=headers).json()
    assert again["updated"] == 0
