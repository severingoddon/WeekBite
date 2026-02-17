from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from database import Base, engine, get_db
from models import Menu, Ingredient, WeekDay, menu_ingredients
from schemas import MenuBase, MenuResponse, WeekDayResponse, WeekDayUpdate

app = FastAPI(title="WeekBite API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

WEEKDAYS = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]


def init_db():
    Base.metadata.create_all(bind=engine)
    db = next(get_db())
    try:
        existing = db.query(WeekDay).count()
        if existing == 0:
            for day in WEEKDAYS:
                db.add(WeekDay(day=day))
            db.commit()
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


# --- Menu Endpoints ---


@app.get("/api/menus", response_model=list[MenuResponse])
def get_menus(db: Session = Depends(get_db)):
    menus = db.query(Menu).order_by(Menu.title).all()
    return [menu_to_response(m) for m in menus]


@app.get("/api/menus/{menu_id}", response_model=MenuResponse)
def get_menu(menu_id: int, db: Session = Depends(get_db)):
    menu = db.query(Menu).filter(Menu.id == menu_id).first()
    if not menu:
        raise HTTPException(status_code=404, detail="Menu not found")
    return menu_to_response(menu)


@app.post("/api/menus", response_model=MenuResponse)
def create_menu(menu_data: MenuBase, db: Session = Depends(get_db)):
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
def update_menu(menu_id: int, menu_data: MenuBase, db: Session = Depends(get_db)):
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
def delete_menu(menu_id: int, db: Session = Depends(get_db)):
    menu = db.query(Menu).filter(Menu.id == menu_id).first()
    if not menu:
        raise HTTPException(status_code=404, detail="Menu not found")
    db.delete(menu)
    db.commit()
    return {"detail": "Menu deleted"}


# --- Week Endpoints ---


@app.get("/api/week", response_model=list[WeekDayResponse])
def get_week(db: Session = Depends(get_db)):
    days = db.query(WeekDay).all()
    day_order = {d: i for i, d in enumerate(WEEKDAYS)}
    days.sort(key=lambda wd: day_order.get(wd.day, 99))
    return [weekday_to_response(wd) for wd in days]


@app.put("/api/week/{day}", response_model=WeekDayResponse)
def update_weekday(day: str, update: WeekDayUpdate, db: Session = Depends(get_db)):
    weekday = db.query(WeekDay).filter(WeekDay.day == day).first()
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


@app.delete("/api/week")
def reset_week(db: Session = Depends(get_db)):
    days = db.query(WeekDay).all()
    for day in days:
        day.menu_id = None
    db.commit()
    return {"detail": "Week reset"}
