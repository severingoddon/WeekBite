from sqlalchemy import Column, Integer, String, ForeignKey, Table, inspect
from sqlalchemy.orm import relationship
from database import Base, engine


menu_ingredients = Table(
    "menu_ingredients",
    Base.metadata,
    Column("menu_id", Integer, ForeignKey("menus.id", ondelete="CASCADE"), primary_key=True),
    Column("ingredient_id", Integer, ForeignKey("ingredients.id", ondelete="CASCADE"), primary_key=True),
)


class Ingredient(Base):
    __tablename__ = "ingredients"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)


class Menu(Base):
    __tablename__ = "menus"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False, unique=True)
    note = Column(String, nullable=False, default="")
    effort_min = Column(Integer, nullable=False, default=20)
    ingredients = relationship("Ingredient", secondary=menu_ingredients, cascade="all, delete", lazy="joined")


class Week(Base):
    __tablename__ = "weeks"

    id = Column(Integer, primary_key=True, index=True)
    start_date = Column(String, nullable=False, unique=True)
    days = relationship("WeekDay", back_populates="week", cascade="all, delete-orphan", lazy="joined")


class WeekDay(Base):
    __tablename__ = "weekdays"

    id = Column(Integer, primary_key=True, index=True)
    day = Column(String, nullable=False)
    week_id = Column(Integer, ForeignKey("weeks.id", ondelete="CASCADE"), nullable=False)
    menu_id = Column(Integer, ForeignKey("menus.id", ondelete="SET NULL"), nullable=True)
    menu = relationship("Menu", lazy="joined")
    week = relationship("Week", back_populates="days")


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    google_id = Column(String, nullable=False, unique=True, index=True)
    email = Column(String, nullable=False)
    name = Column(String, nullable=True)
    picture = Column(String, nullable=True)


class Session(Base):
    __tablename__ = "sessions"

    id = Column(Integer, primary_key=True, index=True)
    token = Column(String, nullable=False, unique=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    user = relationship("User")


def migrate_sessions_table():
    """Drop old sessions table if it lacks user_id column, so it gets recreated."""
    insp = inspect(engine)
    if insp.has_table("sessions"):
        columns = [col["name"] for col in insp.get_columns("sessions")]
        if "user_id" not in columns:
            Session.__table__.drop(engine)
    if insp.has_table("users"):
        columns = [col["name"] for col in insp.get_columns("users")]
        if "picture" not in columns:
            User.__table__.drop(engine)
            if insp.has_table("sessions"):
                Session.__table__.drop(engine)
