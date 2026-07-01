"""Tests for Module 24 monitoring: metrics, readiness, correlation IDs."""
from fastapi.testclient import TestClient

from app.core.metrics import MetricsRegistry
from app.main import app

client = TestClient(app)


def test_correlation_id_header_present_and_echoed() -> None:
    # No inbound id → server generates one.
    resp = client.get("/")
    assert resp.headers.get("X-Request-ID")
    assert "X-Response-Time-ms" in resp.headers

    # Inbound id → echoed back unchanged (trace spans SDK → backend).
    given = "trace-abc-123"
    resp2 = client.get("/", headers={"X-Request-ID": given})
    assert resp2.headers["X-Request-ID"] == given


def test_metrics_prometheus_exposition() -> None:
    client.get("/")  # generate at least one request
    resp = client.get("/api/v1/metrics")
    assert resp.status_code == 200
    assert "text/plain" in resp.headers["content-type"]
    body = resp.text
    assert "# TYPE http_requests_total counter" in body
    assert "http_requests_total{" in body
    assert "app_uptime_seconds" in body


def test_metrics_json_snapshot() -> None:
    client.get("/")
    resp = client.get("/api/v1/metrics.json")
    assert resp.status_code == 200
    body = resp.json()
    assert body["total_requests"] >= 1
    assert isinstance(body["routes"], list)


def test_readiness_probe_ok_with_database() -> None:
    resp = client.get("/api/v1/ready")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "ready"
    assert body["checks"]["database"] == "ok"


# ── Metrics registry unit tests ──────────────────────
def test_registry_aggregates_counts_and_latency() -> None:
    reg = MetricsRegistry()
    reg.record_request("GET", "/x", 200, 10.0)
    reg.record_request("GET", "/x", 200, 30.0)
    reg.record_request("GET", "/x", 500, 5.0)
    snap = reg.snapshot()
    assert snap["total_requests"] == 3
    assert snap["total_errors"] == 1
    row = next(r for r in snap["routes"] if r["route"] == "GET /x")
    assert row["count"] == 3
    assert row["errors"] == 1
    assert row["avg_ms"] == 15.0  # (10+30+5)/3
    assert row["max_ms"] == 30.0


def test_registry_prometheus_escaping_and_format() -> None:
    reg = MetricsRegistry()
    reg.record_request("GET", "/items/{id}", 404, 2.0)
    text = reg.prometheus_text()
    assert 'route="/items/{id}"' in text
    assert 'status="404"' in text
