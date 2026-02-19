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
from models import Menu, Ingredient, Week, WeekDay, Session as SessionModel, User, menu_ingredients, migrate_sessions_table
from schemas import (
    MenuBase,
    MenuResponse,
    WeekDayResponse,
    WeekDayUpdate,
    WeekResponse,
    NextWeekStatus,
    UserResponse,
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
def get_me(session: SessionModel = Depends(get_current_session)):
    user = session.user
    letter = user.email[0].upper() if user.email else "?"
    return UserResponse(email=user.email, name=user.name, avatar_letter=letter, picture=user.picture)


# --- Helpers ---


def get_monday(d: date) -> date:
    return d - timedelta(days=d.weekday())


def create_week(db: DBSession, start_date: date) -> Week:
    week = Week(start_date=start_date.isoformat())
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
        week_count = db.query(Week).count()
        if week_count == 0:
            monday = get_monday(date.today())
            create_week(db, monday)
    finally:
        db.close()


init_db()


def menu_to_response(menu: Menu) -> MenuResponse:
    return MenuResponse(
        id=menu.id,
        title=menu.title,
        ingredients=[ing.name for ing in menu.ingredients],
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


# --- Menu Endpoints ---


@app.get("/api/menus", response_model=list[MenuResponse])
def get_menus(_=Depends(get_current_session), db: DBSession = Depends(get_db)):
    menus = db.query(Menu).order_by(Menu.title).all()
    return [menu_to_response(m) for m in menus]


@app.get("/api/menus/{menu_id}", response_model=MenuResponse)
def get_menu(menu_id: int, _=Depends(get_current_session), db: DBSession = Depends(get_db)):
    menu = db.query(Menu).filter(Menu.id == menu_id).first()
    if not menu:
        raise HTTPException(status_code=404, detail="Menu not found")
    return menu_to_response(menu)


@app.post("/api/menus", response_model=MenuResponse)
def create_menu(menu_data: MenuBase, _=Depends(get_current_session), db: DBSession = Depends(get_db)):
    existing = db.query(Menu).filter(Menu.title == menu_data.title).first()
    if existing:
        raise HTTPException(status_code=400, detail="Menu with this title already exists")

    ingredients = [Ingredient(name=name) for name in menu_data.ingredients]
    menu = Menu(title=menu_data.title, ingredients=ingredients)
    db.add(menu)
    db.commit()
    db.refresh(menu)
    return menu_to_response(menu)


@app.put("/api/menus/{menu_id}", response_model=MenuResponse)
def update_menu(menu_id: int, menu_data: MenuBase, _=Depends(get_current_session), db: DBSession = Depends(get_db)):
    menu = db.query(Menu).filter(Menu.id == menu_id).first()
    if not menu:
        raise HTTPException(status_code=404, detail="Menu not found")

    menu.title = menu_data.title

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
def delete_menu(menu_id: int, _=Depends(get_current_session), db: DBSession = Depends(get_db)):
    menu = db.query(Menu).filter(Menu.id == menu_id).first()
    if not menu:
        raise HTTPException(status_code=404, detail="Menu not found")
    db.delete(menu)
    db.commit()
    return {"detail": "Menu deleted"}


# --- Week Endpoints ---


@app.get("/api/week/next-exists", response_model=NextWeekStatus)
def check_next_week(_=Depends(get_current_session), db: DBSession = Depends(get_db)):
    next_monday = get_monday(date.today()) + timedelta(weeks=1)
    week = db.query(Week).filter(Week.start_date == next_monday.isoformat()).first()
    return NextWeekStatus(exists=week is not None, start_date=next_monday.isoformat())


@app.get("/api/week", response_model=WeekResponse)
def get_week(date_param: str | None = None, _=Depends(get_current_session), db: DBSession = Depends(get_db)):
    if date_param:
        try:
            target = date.fromisoformat(date_param)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")
    else:
        target = date.today()

    monday = get_monday(target)
    week = db.query(Week).filter(Week.start_date == monday.isoformat()).first()

    # Auto-create only for the current week
    if not week and monday == get_monday(date.today()):
        week = create_week(db, monday)

    if not week:
        raise HTTPException(status_code=404, detail="No week found for this date")

    return week_to_response(week)


@app.post("/api/week/next", response_model=WeekResponse)
def create_next_week(_=Depends(get_current_session), db: DBSession = Depends(get_db)):
    next_monday = get_monday(date.today()) + timedelta(weeks=1)
    existing = db.query(Week).filter(Week.start_date == next_monday.isoformat()).first()
    if existing:
        raise HTTPException(status_code=409, detail="Next week already exists")
    week = create_week(db, next_monday)
    return week_to_response(week)


@app.put("/api/week/{week_id}/{day}", response_model=WeekDayResponse)
def update_weekday(week_id: int, day: str, update: WeekDayUpdate, _=Depends(get_current_session), db: DBSession = Depends(get_db)):
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
def reset_week(week_id: int, _=Depends(get_current_session), db: DBSession = Depends(get_db)):
    week = db.query(Week).filter(Week.id == week_id).first()
    if not week:
        raise HTTPException(status_code=404, detail="Week not found")
    for day in week.days:
        day.menu_id = None
    db.commit()
    return {"detail": "Week reset"}
