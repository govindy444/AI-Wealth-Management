"""Integration tests for the AI chat endpoints."""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def test_chat_requires_auth() -> None:
    assert client.post("/api/v1/chat/messages", json={"message": "hi"}).status_code == 401


def test_send_message_starts_conversation_and_replies() -> None:
    resp = client.post(
        "/api/v1/chat/messages",
        json={"message": "Hello there"},
        headers=_auth_headers(),
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["conversation_id"].startswith("conv_")
    assert body["message"]["role"] == "assistant"
    assert "Demo" in body["message"]["content"]  # greets by first name
    assert body["title"] == "Hello there"


def test_investment_reply_carries_explanation() -> None:
    resp = client.post(
        "/api/v1/chat/messages",
        json={"message": "How should I invest my savings?"},
        headers=_auth_headers(),
    )
    insight = resp.json()["message"]["explanation"]
    assert insight is not None
    assert insight["summary"]
    assert 0.0 <= insight["confidence"] <= 1.0


def test_followup_continues_same_conversation() -> None:
    headers = _auth_headers()
    first = client.post(
        "/api/v1/chat/messages", json={"message": "hi"}, headers=headers
    ).json()
    conv_id = first["conversation_id"]

    client.post(
        "/api/v1/chat/messages",
        json={"message": "help me budget", "conversation_id": conv_id},
        headers=headers,
    )

    full = client.get(f"/api/v1/chat/conversations/{conv_id}", headers=headers).json()
    # 2 user + 2 assistant messages.
    assert len(full["messages"]) == 4
    assert full["messages"][0]["role"] == "user"
    assert full["messages"][-1]["role"] == "assistant"


def test_list_and_delete_conversation() -> None:
    headers = _auth_headers()
    conv_id = client.post(
        "/api/v1/chat/messages", json={"message": "hello"}, headers=headers
    ).json()["conversation_id"]

    listed = client.get("/api/v1/chat/conversations", headers=headers).json()
    assert any(c["id"] == conv_id for c in listed)

    deleted = client.delete(f"/api/v1/chat/conversations/{conv_id}", headers=headers)
    assert deleted.status_code == 200
    # Now gone.
    assert client.get(
        f"/api/v1/chat/conversations/{conv_id}", headers=headers
    ).status_code == 404


def test_unknown_conversation_id_is_404() -> None:
    resp = client.post(
        "/api/v1/chat/messages",
        json={"message": "hi", "conversation_id": "conv_does_not_exist"},
        headers=_auth_headers(),
    )
    assert resp.status_code == 404
