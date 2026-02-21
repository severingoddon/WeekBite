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
import { ApiService } from './services/api.service';
import { TourService } from './services/tour.service';
import { TourOverlayComponent } from './components/tour-overlay/tour-overlay.component';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';

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
    MatSnackBarModule,
    TourOverlayComponent,
  ],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss',
})
export class AppComponent {
  sidenavOpen = false;
  user: UserInfo | null = null;
  currentPath = '';

  constructor(
    private router: Router,
    private auth: AuthService,
    private api: ApiService,
    private tour: TourService,
    private snackBar: MatSnackBar,
  ) {
    this.router.events
      .pipe(filter((e) => e instanceof NavigationEnd))
      .subscribe((e) => {
        this.currentPath = (e as NavigationEnd).urlAfterRedirects || (e as NavigationEnd).url;
        if (this.auth.isLoggedIn()) {
          this.loadUser();
        }
      });
  }

  get activeContextName(): string {
    if (!this.user) return 'Privat';
    if (this.user.active_family_id) {
      const family = this.user.families.find((f) => f.id === this.user!.active_family_id);
      return family ? family.name : 'Privat';
    }
    return 'Privat';
  }

  loadUser() {
    this.auth.getMe().subscribe({
      next: (u) => (this.user = u),
      error: () => (this.user = null),
    });
  }

  switchContext(familyId: number | null) {
    this.api.switchContext(familyId).subscribe(() => {
      this.loadUser();
      // Force component re-creation by navigating to a different route first
      const currentUrl = this.router.url;
      const tempUrl = currentUrl === '/' ? '/menus' : '/';
      this.router.navigateByUrl(tempUrl, { skipLocationChange: true }).then(() => {
        this.router.navigateByUrl(currentUrl);
      });
    });
  }

  navigateTo(path: string) {
    this.router.navigate([path]);
    this.sidenavOpen = false;
  }

  resetTour() {
    this.tour.resetAllTours();
    this.snackBar.open('Einführung wird beim nächsten Seitenbesuch erneut angezeigt', 'OK', { duration: 3000 });
  }

  logout() {
    this.user = null;
    this.auth.logout();
  }
}
