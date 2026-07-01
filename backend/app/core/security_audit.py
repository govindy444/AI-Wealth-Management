"""Production security configuration audit.

Flags insecure defaults (placeholder secrets, wildcard CORS). Warnings are logged
at startup in every environment; in production they are hard errors so the service
won't boot misconfigured.
"""
from __future__ import annotations

from app.core.config import Settings

_DEFAULT_JWT = "change-me-in-production-please-32chars-min"
_DEFAULT_AES = "change-me-aes-key-32-bytes-long!!"


def audit_security(settings: Settings) -> list[str]:
    """Returns a list of security issues with the current configuration."""
    issues: list[str] = []
    if settings.jwt_secret_key == _DEFAULT_JWT:
        issues.append("JWT_SECRET_KEY is the default placeholder — set a strong secret.")
    if settings.aes_encryption_key == _DEFAULT_AES:
        issues.append("AES_ENCRYPTION_KEY is the default placeholder — set a real key.")
    if "*" in settings.cors_origins:
        issues.append("CORS allows all origins ('*') — restrict to known hosts.")
    if settings.debug:
        issues.append("DEBUG is enabled — disable in production.")
    return issues


def enforce_security(settings: Settings) -> None:
    """Logs issues; raises in production so a misconfigured service won't start."""
    from app.core.logging import get_logger

    log = get_logger("security")
    issues = audit_security(settings)
    for issue in issues:
        log.warning("security_config_issue", issue=issue)
    if settings.environment == "production" and issues:
        raise RuntimeError(
            "Refusing to start in production with insecure configuration: "
            + "; ".join(issues)
        )
