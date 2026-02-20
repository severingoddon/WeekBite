import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable } from 'rxjs';
import { Family } from '../models/menu.model';

export interface UserInfo {
  email: string;
  name: string | null;
  avatar_letter: string;
  picture: string | null;
  is_admin: boolean;
  active_family_id: number | null;
  families: Family[];
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private tokenKey = 'weekbite_token';

  constructor(
    private http: HttpClient,
    private router: Router,
  ) {}

  loginWithGoogle() {
    // In production, same origin. In dev, the backend runs on port 8000.
    const backendUrl = window.location.port === '4200'
      ? 'http://localhost:8000'
      : '';
    window.location.href = `${backendUrl}/api/auth/google/login`;
  }

  saveToken(token: string) {
    localStorage.setItem(this.tokenKey, token);
  }

  getToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  isLoggedIn(): boolean {
    return !!this.getToken();
  }

  getMe(): Observable<UserInfo> {
    return this.http.get<UserInfo>('/api/auth/me');
  }

  logout() {
    localStorage.removeItem(this.tokenKey);
    this.router.navigate(['/login']);
  }
}
