export interface Menu {
  id: number;
  title: string;
  ingredients: string[];
  note: string;
  effort_min: number;
  is_own?: boolean;
  owner_name?: string | null;
}

export interface MenuCreate {
  title: string;
  ingredients: string[];
  note: string;
  effort_min: number;
}

export interface WeekDay {
  id: number;
  day: string;
  menu: Menu | null;
}

export interface Week {
  id: number;
  start_date: string;
  days: WeekDay[];
}

export interface NextWeekStatus {
  exists: boolean;
  start_date: string;
}

export interface ShoppingItem {
  id: number;
  name: string;
  quantity: string;
  checked: boolean;
  created?: boolean;
}

export interface ShoppingItemCreate {
  name: string;
  quantity: string;
}

export interface FamilyMember {
  user_id: number;
  email: string;
  name: string | null;
  picture: string | null;
}

export interface Family {
  id: number;
  name: string;
  created_by: number;
  members: FamilyMember[];
}

export interface FamilyCreate {
  name: string;
}

export interface PendingInvite {
  id: number;
  family_id: number;
  family_name: string;
  invited_by: string | null;
}
