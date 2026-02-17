import os
import secrets
from datetime import date, timedelta

import bcrypt
from dotenv import load_dotenv
from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from sqlalchemy.orm import Session as DBSession

from database import Base, engine, get_db
from models import Menu, Ingredient, Week, WeekDay, Session as SessionModel, menu_ingredients
from schemas import (
    MenuBase,
    MenuResponse,
    WeekDayResponse,
    WeekDayUpdate,
    WeekResponse,
    NextWeekStatus,
    LoginRequest,
    LoginResponse,
)

load_dotenv()

ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "http://localhost:4200").split(",")

def get_real_ip(request: Request) -> str:
    forwarded = request.headers.get("X-Real-IP")
    if forwarded:
        return forwarded
    return get_remote_address(request)


limiter = Limiter(key_func=get_real_ip)

app = FastAPI(title="WeekBite API")
app.state.limiter = limiter


@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    return JSONResponse(status_code=429, content={"detail": "Too many login attempts. Try again later."})


app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["*"],
    allow_headers=["*"],
)

PASSWORD_HASH = os.getenv("APP_PASSWORD_HASH", "")

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


@app.post("/api/auth/login", response_model=LoginResponse)
@limiter.limit("5/minute")
def login(request: Request, body: LoginRequest, db: DBSession = Depends(get_db)):
    if not PASSWORD_HASH:
        raise HTTPException(status_code=500, detail="No password configured")
    if not bcrypt.checkpw(body.password.encode(), PASSWORD_HASH.encode()):
        raise HTTPException(status_code=401, detail="Wrong password")
    token = secrets.token_urlsafe(32)
    db.add(SessionModel(token=token))
    db.commit()
    return LoginResponse(token=token)


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
