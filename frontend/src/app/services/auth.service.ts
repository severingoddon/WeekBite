import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private tokenKey = 'weekbite_token';

  constructor(
    private http: HttpClient,
    private router: Router,
  ) {}

  login(password: string): Observable<{ token: string }> {
    return this.http.post<{ token: string }>('/api/auth/login', { password }).pipe(
      tap((res) => {
        localStorage.setItem(this.tokenKey, res.token);
      }),
    );
  }

  getToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  isLoggedIn(): boolean {
    return !!this.getToken();
  }

  logout() {
    localStorage.removeItem(this.tokenKey);
    this.router.navigate(['/login']);
  }
}
