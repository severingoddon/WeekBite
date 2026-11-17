from urllib.parse import parse_qs, urlparse

import pytest
from fastapi.responses import RedirectResponse

import main
from models import AllowedEmail, User


@pytest.fixture
def fake_google(monkeypatch):
    """Replace the Google OAuth round trip with a configurable userinfo payload."""
    userinfo = {
        "sub": "google-alice",
        "email": "alice@example.com",
        "email_verified": True,
        "name": "Alice",
        "picture": "https://example.com/alice.png",
    }

    async def fake_authorize_redirect(request, redirect_uri):
        return RedirectResponse(url="https://accounts.google.com/fake")

    async def fake_authorize_access_token(request):
        return {"userinfo": dict(userinfo)}

    monkeypatch.setattr(main.oauth.google, "authorize_redirect", fake_authorize_redirect)
    monkeypatch.setattr(main.oauth.google, "authorize_access_token", fake_authorize_access_token)
    return userinfo


def login(client):
    return client.get("/api/auth/google/callback", follow_redirects=False)


def token_from(response) -> dict[str, str]:
    token = parse_qs(urlparse(response.headers["location"]).query)["token"][0]
    return {"Authorization": f"Bearer {token}"}


def allowlist(db_factory) -> list[str]:
    return sorted(a.email for a in db_factory().query(AllowedEmail).all())


class TestBearerAuth:
    def test_missing_token_is_rejected(self, client):
        assert client.get("/api/menus").status_code == 401

    def test_unknown_token_is_rejected(self, client):
        assert client.get("/api/menus", headers={"Authorization": "Bearer nope"}).status_code == 401

    def test_session_of_user_not_on_allowlist_is_rejected(self, client, make_user):
        headers = make_user("mallory@example.com", allowed=False)
        assert client.get("/api/auth/me", headers=headers).status_code == 403
        assert client.get("/api/menus", headers=headers).status_code == 403

    def test_me(self, client, alice):
        me = client.get("/api/auth/me", headers=alice).json()
        assert me["email"] == "alice@example.com"
        assert me["avatar_letter"] == "A"
        assert me["is_admin"] is False
        assert me["families"] == []


class TestGoogleCallback:
    def test_allowlisted_user_gets_a_session(self, client, fake_google, allow):
        allow("alice@example.com")

        response = login(client)

        assert response.status_code == 307
        assert response.headers["location"].startswith(f"{main.FRONTEND_URL}/login?token=")
        assert client.get("/api/auth/me", headers=token_from(response)).json()["name"] == "Alice"

    def test_ios_login_redirects_to_app_url_scheme(self, client, fake_google, allow):
        allow("alice@example.com")

        client.get("/api/auth/google/login?platform=ios", follow_redirects=False)
        response = login(client)

        assert response.headers["location"].startswith("weekbite://auth?token=")

    def test_allowlist_is_case_insensitive(self, client, fake_google, allow):
        allow("alice@example.com")
        fake_google["email"] = "Alice@Example.COM"

        assert login(client).status_code == 307

    def test_stranger_is_rejected(self, client, fake_google, db_factory):
        assert login(client).status_code == 403
        assert db_factory().query(User).count() == 0

    def test_unverified_email_is_rejected(self, client, fake_google, allow, db_factory):
        allow("alice@example.com")
        fake_google["email_verified"] = False

        assert login(client).status_code == 403
        assert db_factory().query(User).count() == 0

    def test_invited_user_may_sign_in_and_is_added_to_allowlist(self, client, fake_google, bob, db_factory):
        family = client.post("/api/families", json={"name": "Bobs"}, headers=bob).json()
        client.post(f"/api/families/{family['id']}/invite", json={"email": "Alice@example.com"}, headers=bob)

        response = login(client)

        assert response.status_code == 307
        assert "alice@example.com" in allowlist(db_factory)
        # Access must survive accepting the invite (which deletes it)
        alice = token_from(response)
        invite = client.get("/api/auth/me", headers=alice).json()["pending_invites"][0]
        client.post(f"/api/families/invites/{invite['id']}/accept", headers=alice)
        assert client.get("/api/auth/me", headers=alice).status_code == 200
        assert login(client).status_code == 307

    def test_repeat_login_updates_profile_and_keeps_user(self, client, fake_google, allow, db_factory):
        allow("alice@example.com")
        login(client)
        fake_google["name"] = "Alice Renamed"
        login(client)

        users = db_factory().query(User).all()
        assert [u.name for u in users] == ["Alice Renamed"]


class TestAdminAllowlist:
    def test_admin_flag(self, client, make_user):
        admin = make_user("admin@example.com")
        assert client.get("/api/auth/me", headers=admin).json()["is_admin"] is True

    def test_non_admin_cannot_manage_allowlist(self, client, alice):
        assert client.get("/api/admin/members", headers=alice).status_code == 403
        assert client.post("/api/admin/members", json={"email": "x@example.com"}, headers=alice).status_code == 403

    def test_admin_adds_and_removes_emails(self, client, make_user, db_factory):
        admin = make_user("admin@example.com")
        mallory = make_user("mallory@example.com", allowed=False)

        added = client.post("/api/admin/members", json={"email": " Mallory@Example.com "}, headers=admin)
        assert added.json()["email"] == "mallory@example.com"
        assert client.post("/api/admin/members", json={"email": "MALLORY@example.com"}, headers=admin).status_code == 400
        assert client.get("/api/menus", headers=mallory).status_code == 200

        client.delete(f"/api/admin/members/{added.json()['id']}", headers=admin)
        assert client.get("/api/menus", headers=mallory).status_code == 403


def test_startup_seeds_allowlist_from_env(monkeypatch, db_factory):
    monkeypatch.setattr(main, "ALLOWED_EMAILS", {"alice@example.com", "bob@example.com"})
    monkeypatch.setattr(main, "ADMIN_EMAIL", "Admin@Example.com")
    monkeypatch.setattr(main, "get_db", lambda: iter([db_factory()]))

    main.init_db()
    main.init_db()  # idempotent

    assert allowlist(db_factory) == ["admin@example.com", "alice@example.com", "bob@example.com"]
