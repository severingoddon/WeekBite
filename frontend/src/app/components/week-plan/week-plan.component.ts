import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { ApiService } from '../../services/api.service';
import { WeekDay } from '../../models/menu.model';
import { MenuPopupComponent } from '../menu-popup/menu-popup.component';
import { ConfirmDialogComponent } from './confirm-dialog.component';

@Component({
  selector: 'app-week-plan',
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatDialogModule,
    MatSnackBarModule,
  ],
  templateUrl: './week-plan.component.html',
  styleUrl: './week-plan.component.scss',
})
export class WeekPlanComponent implements OnInit {
  week: WeekDay[] = [];

  constructor(
    private api: ApiService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
  ) {}

  ngOnInit() {
    this.loadWeek();
  }

  loadWeek() {
    this.api.getWeek().subscribe((week) => (this.week = week));
  }

  openMenuPopup(weekDay: WeekDay) {
    const dialogRef = this.dialog.open(MenuPopupComponent, {
      width: '100vw',
      maxWidth: '100vw',
      height: '100vh',
      panelClass: 'fullscreen-dialog',
      data: { day: weekDay.day },
    });

    dialogRef.afterClosed().subscribe((menuId) => {
      if (menuId !== undefined) {
        this.api.updateWeekDay(weekDay.day, menuId).subscribe(() => this.loadWeek());
      }
    });
  }

  removeMenu(weekDay: WeekDay, event: Event) {
    event.stopPropagation();
    this.api.updateWeekDay(weekDay.day, null).subscribe(() => this.loadWeek());
  }

  resetWeek() {
    const dialogRef = this.dialog.open(ConfirmDialogComponent, {
      width: '320px',
    });

    dialogRef.afterClosed().subscribe((confirmed) => {
      if (confirmed) {
        this.api.resetWeek().subscribe(() => {
          this.loadWeek();
          this.snackBar.open('Woche zurückgesetzt', 'OK', { duration: 2000 });
        });
      }
    });
  }
}
