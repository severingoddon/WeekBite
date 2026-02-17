from pydantic import BaseModel


class IngredientBase(BaseModel):
    name: str


class IngredientResponse(IngredientBase):
    id: int

    model_config = {"from_attributes": True}


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
