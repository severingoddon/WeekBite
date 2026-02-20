import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Menu, MenuCreate, Week, WeekDay, NextWeekStatus, ShoppingItem, ShoppingItemCreate } from '../models/menu.model';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private baseUrl = '/api';

  constructor(private http: HttpClient) {}

  // Menus
  getMenus(): Observable<Menu[]> {
    return this.http.get<Menu[]>(`${this.baseUrl}/menus`);
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
  getWeek(date?: string): Observable<Week> {
    const params = date ? `?date_param=${date}` : '';
    return this.http.get<Week>(`${this.baseUrl}/week${params}`);
  }

  updateWeekDay(weekId: number, day: string, menuId: number | null): Observable<WeekDay> {
    return this.http.put<WeekDay>(`${this.baseUrl}/week/${weekId}/${day}`, { menu_id: menuId });
  }

  resetWeek(weekId: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/week/${weekId}`);
  }

  getNextWeekStatus(): Observable<NextWeekStatus> {
    return this.http.get<NextWeekStatus>(`${this.baseUrl}/week/next-exists`);
  }

  createNextWeek(): Observable<Week> {
    return this.http.post<Week>(`${this.baseUrl}/week/next`, {});
  }

  // Admin members
  getMembers(): Observable<{ id: number; email: string }[]> {
    return this.http.get<{ id: number; email: string }[]>(`${this.baseUrl}/admin/members`);
  }

  addMember(email: string): Observable<{ id: number; email: string }> {
    return this.http.post<{ id: number; email: string }>(`${this.baseUrl}/admin/members`, { email });
  }

  removeMember(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/admin/members/${id}`);
  }

  // Shopping list
  getShoppingItems(): Observable<ShoppingItem[]> {
    return this.http.get<ShoppingItem[]>(`${this.baseUrl}/shopping`);
  }

  addShoppingItem(item: ShoppingItemCreate): Observable<ShoppingItem> {
    return this.http.post<ShoppingItem>(`${this.baseUrl}/shopping`, item);
  }

  updateShoppingItem(id: number, item: ShoppingItemCreate): Observable<ShoppingItem> {
    return this.http.put<ShoppingItem>(`${this.baseUrl}/shopping/${id}`, item);
  }

  deleteShoppingItem(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/shopping/${id}`);
  }
}
