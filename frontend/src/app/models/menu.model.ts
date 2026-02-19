export interface Menu {
  id: number;
  title: string;
  ingredients: string[];
  note: string;
  effort_min: number;
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
