"""Brute-force protection for login.

Tracks failed attempts per identifier (email) in a sliding window; locks after a
threshold. Successful logins reset the counter. In-memory here; Redis-backed in
production. Keying by email (not IP) keeps shared-IP test clients unaffected.
"""
from __future__ import annotations

import time
from collections import defaultdict


class LoginThrottler:
    def __init__(self, *, max_failures: int = 8, lockout_seconds: int = 300) -> None:
        self._max = max_failures
        self._window = lockout_seconds
        self._failures: dict[str, list[float]] = defaultdict(list)

    def _recent(self, key: str, now: float) -> list[float]:
        cutoff = now - self._window
        recent = [t for t in self._failures[key] if t >= cutoff]
        self._failures[key] = recent
        return recent

    def is_locked(self, identifier: str) -> bool:
        key = identifier.lower()
        return len(self._recent(key, time.monotonic())) >= self._max

    def record_failure(self, identifier: str) -> None:
        key = identifier.lower()
        now = time.monotonic()
        self._recent(key, now).append(now)
        self._failures[key].append(now)

    def reset(self, identifier: str) -> None:
        self._failures.pop(identifier.lower(), None)


# Process-wide instance used by the auth service.
_throttler: LoginThrottler | None = None


def get_login_throttler() -> LoginThrottler:
    global _throttler
    if _throttler is None:
        from app.core.config import get_settings

        s = get_settings()
        _throttler = LoginThrottler(
            max_failures=s.login_max_failures,
            lockout_seconds=s.login_lockout_seconds,
        )
    return _throttler
