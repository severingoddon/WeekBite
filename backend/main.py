import os
import secrets
from datetime import date, timedelta

from authlib.integrations.starlette_client import OAuth
from dotenv import load_dotenv
from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from starlette.middleware.sessions import SessionMiddleware
from sqlalchemy.orm import Session as DBSession

from database import Base, engine, get_db
from models import (
    Menu, Ingredient, Week, WeekDay, Session as SessionModel, User,
    AllowedEmail, ShoppingItem, menu_ingredients, Family, FamilyInvite,
    family_members, migrate_sessions_table,
)
from schemas import (
    MenuBase,
    MenuResponse,
    WeekDayResponse,
    WeekDayUpdate,
    WeekResponse,
    NextWeekStatus,
    UserResponse,
    AllowedEmailCreate,
    AllowedEmailResponse,
    ShoppingItemCreate,
    ShoppingItemResponse,
    FamilyCreate,
    FamilyResponse,
    FamilyMemberResponse,
    FamilyInviteCreate,
    PendingInviteResponse,
    ContextSwitch,
)

load_dotenv()

ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "http://localhost:4200").split(",")
FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:4200")
SESSION_SECRET = os.getenv("SESSION_SECRET", "dev-secret-not-for-production")

app = FastAPI(title="WeekBite API")

app.add_middleware(SessionMiddleware, secret_key=SESSION_SECRET)
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["*"],
    allow_headers=["*"],
)

oauth = OAuth()
oauth.register(
    name="google",
    client_id=os.getenv("GOOGLE_CLIENT_ID"),
    client_secret=os.getenv("GOOGLE_CLIENT_SECRET"),
    server_metadata_url="https://accounts.google.com/.well-known/openid-configuration",
    client_kwargs={"scope": "openid email profile"},
)

ADMIN_EMAIL = os.getenv("ADMIN_EMAIL")
WEEKDAYS = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]


# --- Auth ---


def get_current_session(request: Request, db: DBSession = Depends(get_db)):
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    token = auth[7:]
    session = db.query(SessionModel).filter(SessionModel.token == token).first()
    if not session:
        raise HTTPException(status_code=401, detail="Invalid session")
    return session


def require_admin(session: SessionModel = Depends(get_current_session)):
    if session.user.email != ADMIN_EMAIL:
        raise HTTPException(status_code=403, detail="Admin access required")
    return session


def get_context(session: SessionModel):
    """Returns (user_id, family_id) based on user's active_family_id."""
    user = session.user
    if user.active_family_id:
        # Verify user is member of the family
        is_member = any(f.id == user.active_family_id for f in user.families)
        if is_member:
            return (None, user.active_family_id)
    return (user.id, None)


@app.get("/api/auth/google/login")
async def google_login(request: Request):
    redirect_uri = os.getenv("GOOGLE_REDIRECT_URI", "http://localhost:8000/api/auth/google/callback")
    return await oauth.google.authorize_redirect(request, redirect_uri)


@app.get("/api/auth/google/callback")
async def google_callback(request: Request, db: DBSession = Depends(get_db)):
    token_data = await oauth.google.authorize_access_token(request)
    userinfo = token_data.get("userinfo")
    if not userinfo:
        raise HTTPException(status_code=400, detail="Failed to get user info from Google")

    google_id = userinfo["sub"]
    email = userinfo["email"]
    name = userinfo.get("name", "")
    picture = userinfo.get("picture", "")

    user = db.query(User).filter(User.google_id == google_id).first()
    if user:
        user.email = email
        user.name = name
        user.picture = picture
    else:
        user = User(google_id=google_id, email=email, name=name, picture=picture)
        db.add(user)
    db.flush()

    session_token = secrets.token_urlsafe(32)
    db.add(SessionModel(token=session_token, user_id=user.id))

    db.commit()

    return RedirectResponse(url=f"{FRONTEND_URL}/login?token={session_token}")


@app.get("/api/auth/me", response_model=UserResponse)
def get_me(session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    user = session.user
    letter = user.email[0].upper() if user.email else "?"
    is_admin = user.email == ADMIN_EMAIL

    families_response = []
    for family in user.families:
        members = [
            FamilyMemberResponse(
                user_id=m.id, email=m.email, name=m.name, picture=m.picture
            )
            for m in family.members
        ]
        families_response.append(FamilyResponse(
            id=family.id, name=family.name, created_by=family.created_by, members=members,
        ))

    # Pending invites for this user
    pending = db.query(FamilyInvite).filter(FamilyInvite.email == user.email.lower()).all()
    pending_response = []
    for inv in pending:
        family = db.query(Family).filter(Family.id == inv.family_id).first()
        if family:
            creator = db.query(User).filter(User.id == family.created_by).first()
            pending_response.append(PendingInviteResponse(
                id=inv.id, family_id=family.id, family_name=family.name,
                invited_by=creator.name or creator.email if creator else None,
            ))

    return UserResponse(
        email=user.email, name=user.name, avatar_letter=letter, picture=user.picture,
        is_admin=is_admin, active_family_id=user.active_family_id,
        families=families_response, pending_invites=pending_response,
    )


# --- Helpers ---


def get_monday(d: date) -> date:
    return d - timedelta(days=d.weekday())


def create_week(db: DBSession, start_date: date, user_id: int | None = None, family_id: int | None = None) -> Week:
    week = Week(start_date=start_date.isoformat(), user_id=user_id, family_id=family_id)
    db.add(week)
    db.flush()
    for day_name in WEEKDAYS:
        db.add(WeekDay(day=day_name, week_id=week.id))
    db.commit()
    db.refresh(week)
    return week


def init_db():
    migrate_sessions_table()
    Base.metadata.create_all(bind=engine)
    db = next(get_db())
    try:
        # Seed admin email into allowed_emails (dormant)
        if ADMIN_EMAIL and not db.query(AllowedEmail).filter(AllowedEmail.email == ADMIN_EMAIL).first():
            db.add(AllowedEmail(email=ADMIN_EMAIL))
            db.commit()
    finally:
        db.close()


init_db()


def menu_to_response(menu: Menu, current_user_id: int | None = None, owner_name: str | None = None) -> MenuResponse:
    is_own = current_user_id is None or menu.user_id == current_user_id
    return MenuResponse(
        id=menu.id,
        title=menu.title,
        ingredients=[ing.name for ing in menu.ingredients],
        note=menu.note,
        effort_min=menu.effort_min,
        is_own=is_own,
        owner_name=None if is_own else owner_name,
    )


def weekday_to_response(wd: WeekDay) -> WeekDayResponse:
    return WeekDayResponse(
        id=wd.id,
        day=wd.day,
        menu=menu_to_response(wd.menu) if wd.menu else None,
    )


def week_to_response(week: Week) -> WeekResponse:
    day_order = {d: i for i, d in enumerate(WEEKDAYS)}
    sorted_days = sorted(week.days, key=lambda wd: day_order.get(wd.day, 99))
    return WeekResponse(
        id=week.id,
        start_date=week.start_date,
        days=[weekday_to_response(wd) for wd in sorted_days],
    )


def check_week_access(week: Week, session: SessionModel):
    """Verify user has access to a week (owns it or is member of the family)."""
    user = session.user
    if week.user_id and week.user_id == user.id:
        return
    if week.family_id:
        is_member = any(f.id == week.family_id for f in user.families)
        if is_member:
            return
    raise HTTPException(status_code=403, detail="Access denied")


def check_shopping_access(item: ShoppingItem, session: SessionModel):
    """Verify user has access to a shopping item."""
    user = session.user
    if item.user_id and item.user_id == user.id:
        return
    if item.family_id:
        is_member = any(f.id == item.family_id for f in user.families)
        if is_member:
            return
    raise HTTPException(status_code=403, detail="Access denied")


# --- Family Endpoints ---


@app.get("/api/families", response_model=list[FamilyResponse])
def get_families(session: SessionModel = Depends(get_current_session)):
    user = session.user
    result = []
    for family in user.families:
        members = [
            FamilyMemberResponse(user_id=m.id, email=m.email, name=m.name, picture=m.picture)
            for m in family.members
        ]
        result.append(FamilyResponse(
            id=family.id, name=family.name, created_by=family.created_by, members=members,
        ))
    return result


@app.post("/api/families", response_model=FamilyResponse)
def create_family(data: FamilyCreate, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    user = session.user
    family = Family(name=data.name, created_by=user.id)
    db.add(family)
    db.flush()
    # Auto-add creator as member
    db.execute(family_members.insert().values(family_id=family.id, user_id=user.id))
    db.commit()
    db.refresh(family)
    members = [FamilyMemberResponse(user_id=user.id, email=user.email, name=user.name, picture=user.picture)]
    return FamilyResponse(id=family.id, name=family.name, created_by=family.created_by, members=members)


@app.put("/api/families/{family_id}", response_model=FamilyResponse)
def update_family(family_id: int, data: FamilyCreate, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    family = db.query(Family).filter(Family.id == family_id).first()
    if not family:
        raise HTTPException(status_code=404, detail="Family not found")
    if family.created_by != session.user.id:
        raise HTTPException(status_code=403, detail="Only the creator can rename the family")
    family.name = data.name
    db.commit()
    db.refresh(family)
    members = [
        FamilyMemberResponse(user_id=m.id, email=m.email, name=m.name, picture=m.picture)
        for m in family.members
    ]
    return FamilyResponse(id=family.id, name=family.name, created_by=family.created_by, members=members)


@app.delete("/api/families/{family_id}")
def delete_family(family_id: int, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    family = db.query(Family).filter(Family.id == family_id).first()
    if not family:
        raise HTTPException(status_code=404, detail="Family not found")
    if family.created_by != session.user.id:
        raise HTTPException(status_code=403, detail="Only the creator can delete the family")
    # Reset active_family_id for all members
    db.query(User).filter(User.active_family_id == family_id).update({"active_family_id": None})
    db.delete(family)
    db.commit()
    return {"detail": "Family deleted"}


@app.post("/api/families/{family_id}/invite")
def invite_to_family(family_id: int, data: FamilyInviteCreate, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    family = db.query(Family).filter(Family.id == family_id).first()
    if not family:
        raise HTTPException(status_code=404, detail="Family not found")
    # Only members can invite
    is_member = any(f.id == family_id for f in session.user.families)
    if not is_member:
        raise HTTPException(status_code=403, detail="Not a member of this family")

    email = data.email.strip().lower()

    # Check if user is already a member
    existing_user = db.query(User).filter(User.email == email).first()
    if existing_user:
        already_member = db.execute(
            family_members.select().where(
                family_members.c.family_id == family_id,
                family_members.c.user_id == existing_user.id,
            )
        ).first()
        if already_member:
            raise HTTPException(status_code=400, detail="User is already a member")

    # Check if invite already exists
    existing_invite = db.query(FamilyInvite).filter(
        FamilyInvite.family_id == family_id, FamilyInvite.email == email
    ).first()
    if existing_invite:
        raise HTTPException(status_code=400, detail="Invite already pending")

    db.add(FamilyInvite(family_id=family_id, email=email))
    db.commit()
    return {"detail": "Einladung gesendet"}


@app.post("/api/families/invites/{invite_id}/accept")
def accept_invite(invite_id: int, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    invite = db.query(FamilyInvite).filter(FamilyInvite.id == invite_id).first()
    if not invite:
        raise HTTPException(status_code=404, detail="Invite not found")
    user = session.user
    if invite.email != user.email.lower():
        raise HTTPException(status_code=403, detail="This invite is not for you")
    # Add user to family
    already_member = db.execute(
        family_members.select().where(
            family_members.c.family_id == invite.family_id,
            family_members.c.user_id == user.id,
        )
    ).first()
    if not already_member:
        db.execute(family_members.insert().values(family_id=invite.family_id, user_id=user.id))
    db.delete(invite)
    db.commit()
    return {"detail": "Einladung angenommen"}


@app.post("/api/families/invites/{invite_id}/decline")
def decline_invite(invite_id: int, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    invite = db.query(FamilyInvite).filter(FamilyInvite.id == invite_id).first()
    if not invite:
        raise HTTPException(status_code=404, detail="Invite not found")
    user = session.user
    if invite.email != user.email.lower():
        raise HTTPException(status_code=403, detail="This invite is not for you")
    db.delete(invite)
    db.commit()
    return {"detail": "Einladung abgelehnt"}


@app.delete("/api/families/{family_id}/members/{user_id}")
def remove_family_member(family_id: int, user_id: int, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    family = db.query(Family).filter(Family.id == family_id).first()
    if not family:
        raise HTTPException(status_code=404, detail="Family not found")

    current_user = session.user
    # Can remove yourself (leave) or creator can remove others
    if user_id != current_user.id and family.created_by != current_user.id:
        raise HTTPException(status_code=403, detail="Only the creator can remove members")

    # Creator cannot remove themselves (must delete the family instead)
    if user_id == family.created_by and user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Creator cannot leave. Delete the family instead.")

    db.execute(
        family_members.delete().where(
            family_members.c.family_id == family_id,
            family_members.c.user_id == user_id,
        )
    )
    # Reset active_family_id if the removed user had this family active
    removed_user = db.query(User).filter(User.id == user_id).first()
    if removed_user and removed_user.active_family_id == family_id:
        removed_user.active_family_id = None
    db.commit()
    return {"detail": "Member removed"}


# --- Context Switch ---


@app.put("/api/context")
def switch_context(data: ContextSwitch, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    user = session.user
    if data.family_id is not None:
        is_member = any(f.id == data.family_id for f in user.families)
        if not is_member:
            raise HTTPException(status_code=403, detail="Not a member of this family")
    user.active_family_id = data.family_id
    db.commit()
    return {"detail": "Context switched"}


# --- Menu Endpoints ---


@app.get("/api/menus", response_model=list[MenuResponse])
def get_menus(session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    user_id, family_id = get_context(session)
    current_user_id = session.user.id
    if family_id:
        # In family context: show menus from all family members
        member_rows = db.execute(
            family_members.select().where(family_members.c.family_id == family_id)
        ).fetchall()
        member_ids = [row[1] for row in member_rows]
        menus = db.query(Menu).filter(Menu.user_id.in_(member_ids)).order_by(Menu.title).all()
        # Build owner name lookup for foreign menus
        other_ids = [mid for mid in member_ids if mid != current_user_id]
        owner_map: dict[int, str] = {}
        if other_ids:
            users = db.query(User).filter(User.id.in_(other_ids)).all()
            owner_map = {u.id: u.name or u.email for u in users}
        return [menu_to_response(m, current_user_id, owner_map.get(m.user_id)) for m in menus]
    else:
        menus = db.query(Menu).filter(Menu.user_id == current_user_id).order_by(Menu.title).all()
        return [menu_to_response(m) for m in menus]


@app.get("/api/menus/{menu_id}", response_model=MenuResponse)
def get_menu(menu_id: int, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    menu = db.query(Menu).filter(Menu.id == menu_id, Menu.user_id == session.user.id).first()
    if not menu:
        raise HTTPException(status_code=404, detail="Menu not found")
    return menu_to_response(menu)


@app.post("/api/menus", response_model=MenuResponse)
def create_menu(menu_data: MenuBase, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    existing = db.query(Menu).filter(Menu.title == menu_data.title, Menu.user_id == session.user.id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Menu with this title already exists")

    ingredients = [Ingredient(name=name) for name in menu_data.ingredients]
    menu = Menu(title=menu_data.title, note=menu_data.note, effort_min=menu_data.effort_min, user_id=session.user.id, ingredients=ingredients)
    db.add(menu)
    db.commit()
    db.refresh(menu)
    return menu_to_response(menu)


@app.put("/api/menus/{menu_id}", response_model=MenuResponse)
def update_menu(menu_id: int, menu_data: MenuBase, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    menu = db.query(Menu).filter(Menu.id == menu_id, Menu.user_id == session.user.id).first()
    if not menu:
        raise HTTPException(status_code=404, detail="Menu not found")

    menu.title = menu_data.title
    menu.note = menu_data.note
    menu.effort_min = menu_data.effort_min

    # Remove old ingredients
    db.execute(menu_ingredients.delete().where(menu_ingredients.c.menu_id == menu_id))
    for ing in menu.ingredients:
        db.delete(ing)
    db.flush()

    # Add new ingredients
    new_ingredients = [Ingredient(name=name) for name in menu_data.ingredients]
    menu.ingredients = new_ingredients
    db.commit()
    db.refresh(menu)
    return menu_to_response(menu)


@app.delete("/api/menus/{menu_id}")
def delete_menu(menu_id: int, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    menu = db.query(Menu).filter(Menu.id == menu_id, Menu.user_id == session.user.id).first()
    if not menu:
        raise HTTPException(status_code=404, detail="Menu not found")
    db.delete(menu)
    db.commit()
    return {"detail": "Menu deleted"}


# --- Week Endpoints ---


@app.get("/api/week/next-exists", response_model=NextWeekStatus)
def check_next_week(session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    user_id, family_id = get_context(session)
    next_monday = get_monday(date.today()) + timedelta(weeks=1)
    query = db.query(Week).filter(Week.start_date == next_monday.isoformat())
    if user_id:
        query = query.filter(Week.user_id == user_id)
    else:
        query = query.filter(Week.family_id == family_id)
    week = query.first()
    return NextWeekStatus(exists=week is not None, start_date=next_monday.isoformat())


@app.get("/api/week", response_model=WeekResponse)
def get_week(date_param: str | None = None, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    user_id, family_id = get_context(session)

    if date_param:
        try:
            target = date.fromisoformat(date_param)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")
    else:
        target = date.today()

    monday = get_monday(target)
    query = db.query(Week).filter(Week.start_date == monday.isoformat())
    if user_id:
        query = query.filter(Week.user_id == user_id)
    else:
        query = query.filter(Week.family_id == family_id)
    week = query.first()

    # Auto-create only for the current week
    if not week and monday == get_monday(date.today()):
        week = create_week(db, monday, user_id=user_id, family_id=family_id)

    if not week:
        raise HTTPException(status_code=404, detail="No week found for this date")

    return week_to_response(week)


@app.post("/api/week/next", response_model=WeekResponse)
def create_next_week(session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    user_id, family_id = get_context(session)
    next_monday = get_monday(date.today()) + timedelta(weeks=1)

    query = db.query(Week).filter(Week.start_date == next_monday.isoformat())
    if user_id:
        query = query.filter(Week.user_id == user_id)
    else:
        query = query.filter(Week.family_id == family_id)
    existing = query.first()

    if existing:
        raise HTTPException(status_code=409, detail="Next week already exists")
    week = create_week(db, next_monday, user_id=user_id, family_id=family_id)
    return week_to_response(week)


@app.put("/api/week/{week_id}/{day}", response_model=WeekDayResponse)
def update_weekday(week_id: int, day: str, update: WeekDayUpdate, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    week = db.query(Week).filter(Week.id == week_id).first()
    if not week:
        raise HTTPException(status_code=404, detail="Week not found")
    check_week_access(week, session)

    weekday = (
        db.query(WeekDay)
        .filter(WeekDay.week_id == week_id, WeekDay.day == day)
        .first()
    )
    if not weekday:
        raise HTTPException(status_code=404, detail="Weekday not found")

    if update.menu_id is not None:
        menu = db.query(Menu).filter(Menu.id == update.menu_id).first()
        if not menu:
            raise HTTPException(status_code=404, detail="Menu not found")

    weekday.menu_id = update.menu_id
    db.commit()
    db.refresh(weekday)
    return weekday_to_response(weekday)


@app.delete("/api/week/{week_id}")
def reset_week(week_id: int, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    week = db.query(Week).filter(Week.id == week_id).first()
    if not week:
        raise HTTPException(status_code=404, detail="Week not found")
    check_week_access(week, session)
    for day in week.days:
        day.menu_id = None
    db.commit()
    return {"detail": "Week reset"}


# --- Admin Endpoints ---


@app.get("/api/admin/members", response_model=list[AllowedEmailResponse])
def list_members(_=Depends(require_admin), db: DBSession = Depends(get_db)):
    return db.query(AllowedEmail).order_by(AllowedEmail.email).all()


@app.post("/api/admin/members", response_model=AllowedEmailResponse)
def add_member(data: AllowedEmailCreate, _=Depends(require_admin), db: DBSession = Depends(get_db)):
    existing = db.query(AllowedEmail).filter(AllowedEmail.email == data.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already allowed")
    allowed = AllowedEmail(email=data.email)
    db.add(allowed)
    db.commit()
    db.refresh(allowed)
    return allowed


@app.delete("/api/admin/members/{member_id}")
def remove_member(member_id: int, _=Depends(require_admin), db: DBSession = Depends(get_db)):
    allowed = db.query(AllowedEmail).filter(AllowedEmail.id == member_id).first()
    if not allowed:
        raise HTTPException(status_code=404, detail="Allowed email not found")
    db.delete(allowed)
    db.commit()
    return {"detail": "Email removed"}


# --- Shopping List Endpoints ---


@app.get("/api/shopping", response_model=list[ShoppingItemResponse])
def get_shopping_items(session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    user_id, family_id = get_context(session)
    query = db.query(ShoppingItem)
    if user_id:
        query = query.filter(ShoppingItem.user_id == user_id)
    else:
        query = query.filter(ShoppingItem.family_id == family_id)
    return query.order_by(ShoppingItem.id).all()


@app.post("/api/shopping", response_model=ShoppingItemResponse)
def add_shopping_item(item: ShoppingItemCreate, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    from sqlalchemy import func
    user_id, family_id = get_context(session)

    query = db.query(ShoppingItem).filter(func.lower(ShoppingItem.name) == item.name.strip().lower())
    if user_id:
        query = query.filter(ShoppingItem.user_id == user_id)
    else:
        query = query.filter(ShoppingItem.family_id == family_id)
    existing = query.first()

    if existing:
        return ShoppingItemResponse(id=existing.id, name=existing.name, quantity=existing.quantity, created=False)
    shopping_item = ShoppingItem(name=item.name.strip(), quantity=item.quantity, user_id=user_id, family_id=family_id)
    db.add(shopping_item)
    db.commit()
    db.refresh(shopping_item)
    return shopping_item


@app.put("/api/shopping/{item_id}", response_model=ShoppingItemResponse)
def update_shopping_item(item_id: int, item: ShoppingItemCreate, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    shopping_item = db.query(ShoppingItem).filter(ShoppingItem.id == item_id).first()
    if not shopping_item:
        raise HTTPException(status_code=404, detail="Shopping item not found")
    check_shopping_access(shopping_item, session)
    shopping_item.name = item.name
    shopping_item.quantity = item.quantity
    db.commit()
    db.refresh(shopping_item)
    return shopping_item


@app.patch("/api/shopping/{item_id}/toggle", response_model=ShoppingItemResponse)
def toggle_shopping_item(item_id: int, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    shopping_item = db.query(ShoppingItem).filter(ShoppingItem.id == item_id).first()
    if not shopping_item:
        raise HTTPException(status_code=404, detail="Shopping item not found")
    check_shopping_access(shopping_item, session)
    shopping_item.checked = not shopping_item.checked
    db.commit()
    db.refresh(shopping_item)
    return shopping_item


@app.delete("/api/shopping/{item_id}")
def delete_shopping_item(item_id: int, session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    shopping_item = db.query(ShoppingItem).filter(ShoppingItem.id == item_id).first()
    if not shopping_item:
        raise HTTPException(status_code=404, detail="Shopping item not found")
    check_shopping_access(shopping_item, session)
    db.delete(shopping_item)
    db.commit()
    return {"detail": "Shopping item deleted"}


@app.delete("/api/shopping")
def clear_shopping_list(session: SessionModel = Depends(get_current_session), db: DBSession = Depends(get_db)):
    user_id, family_id = get_context(session)
    query = db.query(ShoppingItem)
    if user_id:
        query = query.filter(ShoppingItem.user_id == user_id)
    else:
        query = query.filter(ShoppingItem.family_id == family_id)
    query.delete()
    db.commit()
    return {"detail": "Shopping list cleared"}
