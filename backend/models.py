from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Table, inspect, text
from sqlalchemy.orm import relationship
from database import Base, engine


menu_ingredients = Table(
    "menu_ingredients",
    Base.metadata,
    Column("menu_id", Integer, ForeignKey("menus.id", ondelete="CASCADE"), primary_key=True),
    Column("ingredient_id", Integer, ForeignKey("ingredients.id", ondelete="CASCADE"), primary_key=True),
)


family_members = Table(
    "family_members",
    Base.metadata,
    Column("family_id", Integer, ForeignKey("families.id", ondelete="CASCADE"), primary_key=True),
    Column("user_id", Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
)


class Ingredient(Base):
    __tablename__ = "ingredients"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)


class Family(Base):
    __tablename__ = "families"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    members = relationship("User", secondary=family_members, back_populates="families")


class FamilyInvite(Base):
    __tablename__ = "family_invites"

    id = Column(Integer, primary_key=True, index=True)
    family_id = Column(Integer, ForeignKey("families.id", ondelete="CASCADE"), nullable=False)
    email = Column(String, nullable=False)


class Menu(Base):
    __tablename__ = "menus"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    note = Column(String, nullable=False, default="")
    effort_min = Column(Integer, nullable=False, default=20)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    ingredients = relationship("Ingredient", secondary=menu_ingredients, cascade="all, delete", lazy="joined")


class Week(Base):
    __tablename__ = "weeks"

    id = Column(Integer, primary_key=True, index=True)
    start_date = Column(String, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    family_id = Column(Integer, ForeignKey("families.id", ondelete="CASCADE"), nullable=True)
    days = relationship("WeekDay", back_populates="week", cascade="all, delete-orphan", lazy="joined")


class WeekDay(Base):
    __tablename__ = "weekdays"

    id = Column(Integer, primary_key=True, index=True)
    day = Column(String, nullable=False)
    week_id = Column(Integer, ForeignKey("weeks.id", ondelete="CASCADE"), nullable=False)
    menu_id = Column(Integer, ForeignKey("menus.id", ondelete="SET NULL"), nullable=True)
    menu = relationship("Menu", lazy="joined")
    week = relationship("Week", back_populates="days")


class AllowedEmail(Base):
    __tablename__ = "allowed_emails"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, nullable=False, unique=True)


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    google_id = Column(String, nullable=False, unique=True, index=True)
    email = Column(String, nullable=False)
    name = Column(String, nullable=True)
    picture = Column(String, nullable=True)
    active_family_id = Column(Integer, ForeignKey("families.id", ondelete="SET NULL"), nullable=True)
    families = relationship("Family", secondary=family_members, back_populates="members")


class Session(Base):
    __tablename__ = "sessions"

    id = Column(Integer, primary_key=True, index=True)
    token = Column(String, nullable=False, unique=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    user = relationship("User")


class ShoppingItem(Base):
    __tablename__ = "shopping_items"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    quantity = Column(String, nullable=False, default="")
    checked = Column(Boolean, nullable=False, default=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    family_id = Column(Integer, ForeignKey("families.id", ondelete="CASCADE"), nullable=True)


def migrate_sessions_table():
    """Drop old tables if they lack required columns, so they get recreated."""
    insp = inspect(engine)

    # Drop week_users if it exists (no longer needed)
    if insp.has_table("week_users"):
        with engine.connect() as conn:
            conn.execute(text("DROP TABLE week_users"))
            conn.commit()

    # Drop and recreate weeks/weekdays if they lack user_id/family_id
    if insp.has_table("weeks"):
        columns = [col["name"] for col in insp.get_columns("weeks")]
        if "user_id" not in columns or "family_id" not in columns:
            if insp.has_table("weekdays"):
                WeekDay.__table__.drop(engine)
            Week.__table__.drop(engine)

    # Drop and recreate shopping_items if it lacks user_id/family_id
    if insp.has_table("shopping_items"):
        columns = [col["name"] for col in insp.get_columns("shopping_items")]
        if "user_id" not in columns or "family_id" not in columns:
            ShoppingItem.__table__.drop(engine)

    # Drop and recreate menus if it lacks user_id
    if insp.has_table("menus"):
        columns = [col["name"] for col in insp.get_columns("menus")]
        if "user_id" not in columns:
            if insp.has_table("menu_ingredients"):
                menu_ingredients.drop(engine)
            Menu.__table__.drop(engine)

    # Drop and recreate users if it lacks active_family_id
    if insp.has_table("users"):
        columns = [col["name"] for col in insp.get_columns("users")]
        if "active_family_id" not in columns:
            # Must drop sessions first due to FK
            if insp.has_table("sessions"):
                Session.__table__.drop(engine)
            User.__table__.drop(engine)

    if insp.has_table("sessions"):
        columns = [col["name"] for col in insp.get_columns("sessions")]
        if "user_id" not in columns:
            Session.__table__.drop(engine)
