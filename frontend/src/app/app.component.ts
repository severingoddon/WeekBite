import { Component } from '@angular/core';
import { NavigationEnd, Router, RouterOutlet } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatListModule } from '@angular/material/list';
import { MatMenuModule } from '@angular/material/menu';
import { MatDividerModule } from '@angular/material/divider';
import { filter } from 'rxjs';
import { AuthService, UserInfo } from './services/auth.service';

@Component({
  selector: 'app-root',
  imports: [
    RouterOutlet,
    MatToolbarModule,
    MatIconModule,
    MatButtonModule,
    MatSidenavModule,
    MatListModule,
    MatMenuModule,
    MatDividerModule,
  ],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss',
})
export class AppComponent {
  sidenavOpen = false;
  user: UserInfo | null = null;

  constructor(
    private router: Router,
    private auth: AuthService,
  ) {
    this.router.events
      .pipe(filter((e) => e instanceof NavigationEnd))
      .subscribe(() => {
        if (this.auth.isLoggedIn() && !this.user) {
          this.auth.getMe().subscribe({
            next: (u) => (this.user = u),
            error: () => (this.user = null),
          });
        }
      });
  }

  navigateTo(path: string) {
    this.router.navigate([path]);
    this.sidenavOpen = false;
  }

  logout() {
    this.user = null;
    this.auth.logout();
  }
}
