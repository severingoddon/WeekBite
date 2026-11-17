import os
import tempfile

# Configure the app before it is imported: main.py reads these at import time.
# Values set here take precedence over a local backend/.env (load_dotenv doesn't override).
os.environ["DATA_DIR"] = tempfile.mkdtemp(prefix="weekbite-tests-")
os.environ["ADMIN_EMAIL"] = "admin@example.com"
os.environ["ALLOWED_EMAILS"] = ""
os.environ["SESSION_SECRET"] = "test-secret"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

import main  # noqa: E402
from database import Base, get_db  # noqa: E402
from models import AllowedEmail, Session as SessionModel, User  # noqa: E402


@pytest.fixture
def db_factory():
    """A fresh in-memory database per test."""
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    yield sessionmaker(bind=engine, autoflush=False, autocommit=False)
    engine.dispose()


@pytest.fixture
def client(db_factory):
    def override_get_db():
        db = db_factory()
        try:
            yield db
        finally:
            db.close()

    main.app.dependency_overrides[get_db] = override_get_db
    with TestClient(main.app) as c:
        yield c
    main.app.dependency_overrides.clear()


@pytest.fixture
def allow(db_factory):
    """Put an email on the allowlist."""

    def _allow(email: str) -> None:
        db = db_factory()
        db.add(AllowedEmail(email=email.lower()))
        db.commit()
        db.close()

    return _allow


@pytest.fixture
def make_user(db_factory, allow):
    """Create a user with a session directly in the DB and return auth headers."""

    def _make(email: str, allowed: bool = True) -> dict[str, str]:
        if allowed:
            allow(email)
        db = db_factory()
        user = User(google_id=f"google-{email}", email=email, name=email.split("@")[0].title())
        db.add(user)
        db.flush()
        token = f"token-{email}"
        db.add(SessionModel(token=token, user_id=user.id))
        db.commit()
        db.close()
        return {"Authorization": f"Bearer {token}"}

    return _make


@pytest.fixture
def alice(make_user):
    return make_user("alice@example.com")


@pytest.fixture
def bob(make_user):
    return make_user("bob@example.com")


@pytest.fixture
def carol(make_user):
    return make_user("carol@example.com")


@pytest.fixture
def user_id(db_factory):
    def _user_id(headers: dict[str, str]) -> int:
        token = headers["Authorization"].removeprefix("Bearer ")
        return db_factory().query(SessionModel).filter(SessionModel.token == token).one().user_id

    return _user_id


@pytest.fixture
def create_menu(client):
    def _create(headers: dict[str, str], title: str, **fields) -> dict:
        payload = {"title": title, "ingredients": [], **fields}
        response = client.post("/api/menus", json=payload, headers=headers)
        assert response.status_code == 200, response.text
        return response.json()

    return _create


@pytest.fixture
def family(client):
    """Create a family owned by `owner` with the given members (invited and accepted)."""

    def _family(owner: dict[str, str], *members: dict[str, str], name: str = "Family") -> dict:
        created = client.post("/api/families", json={"name": name}, headers=owner).json()
        for member in members:
            email = client.get("/api/auth/me", headers=member).json()["email"]
            assert client.post(f"/api/families/{created['id']}/invite", json={"email": email}, headers=owner).status_code == 200
            invite = next(i for i in client.get("/api/auth/me", headers=member).json()["pending_invites"]
                          if i["family_id"] == created["id"])
            assert client.post(f"/api/families/invites/{invite['id']}/accept", headers=member).status_code == 200
        return created

    return _family


@pytest.fixture
def use_context(client):
    def _use(headers: dict[str, str], family_id: int | None) -> None:
        assert client.put("/api/context", json={"family_id": family_id}, headers=headers).status_code == 200

    return _use
