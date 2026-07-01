"""In-process application metrics registry.

A dependency-free, thread-safe metrics collector that records HTTP request
counts and latencies per route, and exposes them in Prometheus text exposition
format (so Prometheus/Grafana can scrape `/api/v1/metrics`) plus a JSON snapshot
for the demo dashboard. Production can swap this for a StatsD/OTel exporter — the
`MetricsRegistry` interface stays the same.
"""
from __future__ import annotations

import threading
import time
from collections import defaultdict
from dataclasses import dataclass, field


@dataclass
class _RouteStat:
    count: int = 0
    errors: int = 0           # responses with status >= 500
    total_duration_ms: float = 0.0
    max_duration_ms: float = 0.0
    status_counts: dict[int, int] = field(default_factory=lambda: defaultdict(int))


class MetricsRegistry:
    """Aggregates request metrics keyed by `METHOD route_template`."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._routes: dict[str, _RouteStat] = defaultdict(_RouteStat)
        self._total_requests = 0
        self._total_errors = 0
        self._started_at = time.time()

    def record_request(
        self, method: str, route: str, status_code: int, duration_ms: float
    ) -> None:
        key = f"{method} {route}"
        with self._lock:
            stat = self._routes[key]
            stat.count += 1
            stat.total_duration_ms += duration_ms
            stat.max_duration_ms = max(stat.max_duration_ms, duration_ms)
            stat.status_counts[status_code] += 1
            self._total_requests += 1
            if status_code >= 500:
                stat.errors += 1
                self._total_errors += 1

    def uptime_seconds(self) -> float:
        return time.time() - self._started_at

    def snapshot(self) -> dict:
        """JSON-friendly summary for the monitoring dashboard."""
        with self._lock:
            routes = []
            for key, s in sorted(self._routes.items()):
                avg = s.total_duration_ms / s.count if s.count else 0.0
                routes.append(
                    {
                        "route": key,
                        "count": s.count,
                        "errors": s.errors,
                        "avg_ms": round(avg, 2),
                        "max_ms": round(s.max_duration_ms, 2),
                        "status_counts": dict(s.status_counts),
                    }
                )
            return {
                "uptime_seconds": round(self.uptime_seconds(), 1),
                "total_requests": self._total_requests,
                "total_errors": self._total_errors,
                "routes": routes,
            }

    def prometheus_text(self) -> str:
        """Render metrics in Prometheus text exposition format (v0.0.4)."""
        lines: list[str] = []
        with self._lock:
            lines.append("# HELP app_uptime_seconds Process uptime in seconds.")
            lines.append("# TYPE app_uptime_seconds gauge")
            lines.append(f"app_uptime_seconds {self.uptime_seconds():.1f}")

            lines.append("# HELP http_requests_total Total HTTP requests.")
            lines.append("# TYPE http_requests_total counter")
            for key, s in sorted(self._routes.items()):
                method, _, route = key.partition(" ")
                for status, n in sorted(s.status_counts.items()):
                    lines.append(
                        f'http_requests_total{{method="{method}",'
                        f'route="{_escape(route)}",status="{status}"}} {n}'
                    )

            lines.append(
                "# HELP http_request_duration_ms_sum Summed request duration (ms)."
            )
            lines.append("# TYPE http_request_duration_ms_sum counter")
            for key, s in sorted(self._routes.items()):
                method, _, route = key.partition(" ")
                lines.append(
                    f'http_request_duration_ms_sum{{method="{method}",'
                    f'route="{_escape(route)}"}} {s.total_duration_ms:.2f}'
                )
        return "\n".join(lines) + "\n"

    def reset(self) -> None:
        with self._lock:
            self._routes.clear()
            self._total_requests = 0
            self._total_errors = 0
            self._started_at = time.time()


def _escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


_registry: MetricsRegistry | None = None


def get_metrics_registry() -> MetricsRegistry:
    global _registry
    if _registry is None:
        _registry = MetricsRegistry()
    return _registry
