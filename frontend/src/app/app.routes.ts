import { Routes } from '@angular/router';
import { WeekPlanComponent } from './components/week-plan/week-plan.component';
import { MenuManagementComponent } from './components/menu-management/menu-management.component';
import { LoginComponent } from './components/login/login.component';
import { AccessDeniedComponent } from './components/access-denied/access-denied.component';
import { InviteComponent } from './components/invite/invite.component';
import { authGuard } from './services/auth.guard';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'access-denied', component: AccessDeniedComponent },
  { path: '', component: WeekPlanComponent, canActivate: [authGuard] },
  { path: 'menus', component: MenuManagementComponent, canActivate: [authGuard] },
  { path: 'invite', component: InviteComponent, canActivate: [authGuard] },
  { path: '**', redirectTo: '' },
];
