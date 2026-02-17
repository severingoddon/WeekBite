from pydantic import BaseModel


class MenuBase(BaseModel):
    title: str
    ingredients: list[str]


class MenuResponse(BaseModel):
    id: int
    title: str
    ingredients: list[str]

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


class LoginRequest(BaseModel):
    password: str


class LoginResponse(BaseModel):
    token: str
