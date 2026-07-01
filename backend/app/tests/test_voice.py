"""Integration tests for the Voice Assistant endpoints."""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)

DEMO = {"email": "demo@idbi.example", "password": "Password@123"}


def _auth_headers() -> dict[str, str]:
    tokens = client.post("/api/v1/auth/login", json=DEMO).json()
    return {"Authorization": f"Bearer {tokens['access_token']}"}


def test_voice_requires_auth() -> None:
    assert client.get("/api/v1/voice/config").status_code == 401


def test_voice_config_lists_locales_and_wake_word() -> None:
    body = client.get("/api/v1/voice/config", headers=_auth_headers()).json()
    codes = {loc["code"] for loc in body["locales"]}
    assert {"en", "hi", "ta"}.issubset(codes)
    assert body["default_locale"] == "en-IN"
    assert body["wake_word"]
    assert 0.0 <= body["default_rate"] <= 1.0


def test_voice_turn_returns_spoken_ready_reply() -> None:
    body = client.post(
        "/api/v1/voice/turn",
        json={"transcript": "How should I invest?", "locale": "hi"},
        headers=_auth_headers(),
    ).json()
    assert body["transcript"] == "How should I invest?"
    assert body["reply"]["role"] == "assistant"
    assert body["reply"]["content"]
    assert body["voice"]["locale"] == "hi-IN"  # ISO code mapped to bcp47
    assert body["conversation_id"].startswith("conv_")


def test_voice_turn_continues_same_conversation_as_chat() -> None:
    headers = _auth_headers()
    # Start via voice...
    turn = client.post(
        "/api/v1/voice/turn",
        json={"transcript": "hi"},
        headers=headers,
    ).json()
    conv_id = turn["conversation_id"]
    # ...continue the SAME conversation via the chat endpoint.
    client.post(
        "/api/v1/chat/messages",
        json={"message": "help me budget", "conversation_id": conv_id},
        headers=headers,
    )
    full = client.get(f"/api/v1/chat/conversations/{conv_id}", headers=headers).json()
    assert len(full["messages"]) == 4  # voice user+assistant, chat user+assistant


def test_voice_turn_unknown_locale_falls_back_to_default() -> None:
    body = client.post(
        "/api/v1/voice/turn",
        json={"transcript": "hello", "locale": "zz-ZZ"},
        headers=_auth_headers(),
    ).json()
    assert body["voice"]["locale"] == "en-IN"
