import { Routes } from '@angular/router';
import { WeekPlanComponent } from './components/week-plan/week-plan.component';
import { MenuManagementComponent } from './components/menu-management/menu-management.component';
import { LoginComponent } from './components/login/login.component';
import { ShoppingListComponent } from './components/shopping-list/shopping-list.component';
import { FamilyManagementComponent } from './components/family-management/family-management.component';
import { authGuard } from './services/auth.guard';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: '', component: WeekPlanComponent, canActivate: [authGuard] },
  { path: 'menus', component: MenuManagementComponent, canActivate: [authGuard] },
  { path: 'shopping', component: ShoppingListComponent, canActivate: [authGuard] },
  { path: 'families', component: FamilyManagementComponent, canActivate: [authGuard] },
  { path: '**', redirectTo: '' },
];
