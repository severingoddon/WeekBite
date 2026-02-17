from sqlalchemy import Column, Integer, String, ForeignKey, Table
from sqlalchemy.orm import relationship
from database import Base

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
