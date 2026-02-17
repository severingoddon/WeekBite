import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Menu, MenuCreate, WeekDay } from '../models/menu.model';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private baseUrl = '/api';

  constructor(private http: HttpClient) {}

  // Menus
  getMenus(): Observable<Menu[]> {
    return this.http.get<Menu[]>(`${this.baseUrl}/menus`);
  }

  getMenu(id: number): Observable<Menu> {
    return this.http.get<Menu>(`${this.baseUrl}/menus/${id}`);
  }

  createMenu(menu: MenuCreate): Observable<Menu> {
    return this.http.post<Menu>(`${this.baseUrl}/menus`, menu);
  }

  updateMenu(id: number, menu: MenuCreate): Observable<Menu> {
    return this.http.put<Menu>(`${this.baseUrl}/menus/${id}`, menu);
  }

  deleteMenu(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/menus/${id}`);
  }

  // Week
  getWeek(): Observable<WeekDay[]> {
    return this.http.get<WeekDay[]>(`${this.baseUrl}/week`);
  }

  updateWeekDay(day: string, menuId: number | null): Observable<WeekDay> {
    return this.http.put<WeekDay>(`${this.baseUrl}/week/${day}`, { menu_id: menuId });
  }

  resetWeek(): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/week`);
  }
}
