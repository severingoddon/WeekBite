import { Routes } from '@angular/router';
import { WeekPlanComponent } from './components/week-plan/week-plan.component';
import { MenuManagementComponent } from './components/menu-management/menu-management.component';
import { LoginComponent } from './components/login/login.component';
import { authGuard } from './services/auth.guard';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: '', component: WeekPlanComponent, canActivate: [authGuard] },
  { path: 'menus', component: MenuManagementComponent, canActivate: [authGuard] },
  { path: '**', redirectTo: '' },
];
