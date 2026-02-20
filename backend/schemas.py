from pydantic import BaseModel


class MenuBase(BaseModel):
    title: str
    ingredients: list[str]
    note: str = ""
    effort_min: int = 20


class MenuResponse(BaseModel):
    id: int
    title: str
    ingredients: list[str]
    note: str
    effort_min: int

    model_config = {"from_attributes": True}


class WeekDayResponse(BaseModel):
    id: int
    day: str
    menu: MenuResponse | None = None

    model_config = {"from_attributes": True}


class WeekDayUpdate(BaseModel):
    menu_id: int | None = None


class WeekResponse(BaseModel):
    id: int
    start_date: str
    days: list[WeekDayResponse]

    model_config = {"from_attributes": True}


class NextWeekStatus(BaseModel):
    exists: bool
    start_date: str


class UserResponse(BaseModel):
    email: str
    name: str | None
    avatar_letter: str
    picture: str | None
    is_admin: bool = False
    is_allowed: bool = False


class AllowedEmailCreate(BaseModel):
    email: str


class AllowedEmailResponse(BaseModel):
    id: int
    email: str

    model_config = {"from_attributes": True}


class ShoppingItemCreate(BaseModel):
    name: str
    quantity: str = ""


class ShoppingItemResponse(BaseModel):
    id: int
    name: str
    quantity: str
    created: bool = True

    model_config = {"from_attributes": True}
