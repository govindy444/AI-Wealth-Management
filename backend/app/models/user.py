"""User domain model.

A lightweight dataclass for now; the SQLAlchemy ORM mapping and persistence land
in Module 20 (Backend APIs / database). The repository abstraction keeps services
decoupled from the storage choice.
"""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class User:
    id: str
    email: str
    full_name: str
    hashed_password: str
    roles: list[str] = field(default_factory=lambda: ["customer"])
    is_active: bool = True
