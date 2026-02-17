export interface Menu {
  id: number;
  title: string;
  ingredients: string[];
}

export interface MenuCreate {
  title: string;
  ingredients: string[];
}

export interface WeekDay {
  id: number;
  day: string;
  menu: Menu | null;
}
