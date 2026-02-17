import { Routes } from '@angular/router';
import { WeekPlanComponent } from './components/week-plan/week-plan.component';
import { MenuManagementComponent } from './components/menu-management/menu-management.component';

export const routes: Routes = [
  { path: '', component: WeekPlanComponent },
  { path: 'menus', component: MenuManagementComponent },
  { path: '**', redirectTo: '' },
];
