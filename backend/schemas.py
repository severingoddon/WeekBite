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
    is_own: bool = True
    owner_name: str | None = None

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


class FamilyCreate(BaseModel):
    name: str


class FamilyMemberResponse(BaseModel):
    user_id: int
    email: str
    name: str | None
    picture: str | None

    model_config = {"from_attributes": True}


class FamilyResponse(BaseModel):
    id: int
    name: str
    created_by: int
    members: list[FamilyMemberResponse]

    model_config = {"from_attributes": True}


class FamilyInviteCreate(BaseModel):
    email: str


class PendingInviteResponse(BaseModel):
    id: int
    family_id: int
    family_name: str
    invited_by: str | None = None

    model_config = {"from_attributes": True}


class ContextSwitch(BaseModel):
    family_id: int | None = None


class UserResponse(BaseModel):
    email: str
    name: str | None
    avatar_letter: str
    picture: str | None
    is_admin: bool = False
    active_family_id: int | None = None
    families: list[FamilyResponse] = []
    pending_invites: list[PendingInviteResponse] = []


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
    checked: bool = False
    created: bool = True

    model_config = {"from_attributes": True}
