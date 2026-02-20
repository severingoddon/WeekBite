import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Menu, MenuCreate, Week, WeekDay, NextWeekStatus, ShoppingItem, ShoppingItemCreate, Family, FamilyCreate } from '../models/menu.model';

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

  toggleShoppingItem(id: number): Observable<ShoppingItem> {
    return this.http.patch<ShoppingItem>(`${this.baseUrl}/shopping/${id}/toggle`, {});
  }

  deleteShoppingItem(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/shopping/${id}`);
  }

  clearShoppingList(): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/shopping`);
  }

  // Families
  getFamilies(): Observable<Family[]> {
    return this.http.get<Family[]>(`${this.baseUrl}/families`);
  }

  createFamily(data: FamilyCreate): Observable<Family> {
    return this.http.post<Family>(`${this.baseUrl}/families`, data);
  }

  updateFamily(id: number, data: FamilyCreate): Observable<Family> {
    return this.http.put<Family>(`${this.baseUrl}/families/${id}`, data);
  }

  deleteFamily(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/families/${id}`);
  }

  inviteToFamily(familyId: number, email: string): Observable<any> {
    return this.http.post(`${this.baseUrl}/families/${familyId}/invite`, { email });
  }

  removeFamilyMember(familyId: number, userId: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/families/${familyId}/members/${userId}`);
  }

  // Context
  switchContext(familyId: number | null): Observable<any> {
    return this.http.put(`${this.baseUrl}/context`, { family_id: familyId });
  }
}
