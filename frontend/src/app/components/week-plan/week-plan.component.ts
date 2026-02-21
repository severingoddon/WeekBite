import { Component, OnInit, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatDatepicker, MatDatepickerModule } from '@angular/material/datepicker';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatMenuModule } from '@angular/material/menu';
import { ApiService } from '../../services/api.service';
import { TourService } from '../../services/tour.service';
import { Week, WeekDay } from '../../models/menu.model';
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
    MatDatepickerModule,
    MatFormFieldModule,
    MatInputModule,
    MatMenuModule,
  ],
  templateUrl: './week-plan.component.html',
  styleUrl: './week-plan.component.scss',
})
export class WeekPlanComponent implements OnInit {
  currentWeek: Week | null = null;
  nextWeekExists = false;
  nextWeekStartDate = '';
  noWeekFound = false;

  @ViewChild('picker') picker!: MatDatepicker<Date>;

  constructor(
    private api: ApiService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private tour: TourService,
  ) {}

  ngOnInit() {
    this.loadWeek();
  }

  private tryStartTour() {
    if (this.tour.hasSeenTour('week-plan')) return;
    setTimeout(() => {
      this.tour.startTour('week-plan', [
        {
          selector: '[data-tour="day-card"]',
          title: 'Tage belegen',
          text: 'Tippe auf einen Tag, um ein Menu zuzuweisen. So planst du deine Woche.',
          position: 'bottom',
        },
        {
          selector: '[data-tour="next-week-btn"]',
          title: 'Woche wechseln',
          text: 'Erstelle die nächste Woche oder wechsle zwischen bestehenden Wochen.',
          position: 'bottom',
        },
        {
          selector: '[data-tour="date-picker-btn"]',
          title: 'Datum wählen',
          text: 'Springe direkt zu einer bestimmten Woche über den Kalender.',
          position: 'bottom',
        },
        {
          selector: '[data-tour="context-switcher"]',
          title: 'Kontext wechseln',
          text: 'Wechsle hier zwischen deinem privaten Bereich und deinen Familien. Wochenpläne und Einkaufslisten werden pro Kontext getrennt.',
          position: 'bottom',
        },
      ]);
    }, 300);
  }

  get weekLabel(): string {
    if (!this.currentWeek) return '';
    const start = new Date(this.currentWeek.start_date + 'T00:00:00');
    const end = new Date(start);
    end.setDate(end.getDate() + 6);
    return `${this.formatDate(start)} – ${this.formatDate(end)}`;
  }

  get isCurrentWeek(): boolean {
    if (!this.currentWeek) return false;
    const today = new Date();
    const monday = this.getMonday(today);
    return this.currentWeek.start_date === this.toISODate(monday);
  }

  loadWeek(date?: string) {
    this.noWeekFound = false;
    this.api.getWeek(date).subscribe({
      next: (week) => {
        this.currentWeek = week;
        this.checkNextWeek();
        this.tryStartTour();
      },
      error: (err) => {
        if (err.status === 404) {
          this.currentWeek = null;
          this.noWeekFound = true;
        } else if (err.status !== 401) {
          this.snackBar.open('Keine Woche für dieses Datum gefunden', 'OK', { duration: 3000 });
        }
      },
    });
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
      if (menuId !== undefined && this.currentWeek) {
        this.api.updateWeekDay(this.currentWeek.id, weekDay.day, menuId).subscribe(() => this.loadWeek(this.currentWeek!.start_date));
      }
    });
  }

  removeMenu(weekDay: WeekDay, event: Event) {
    event.stopPropagation();
    if (this.currentWeek) {
      this.api.updateWeekDay(this.currentWeek.id, weekDay.day, null).subscribe(() => this.loadWeek(this.currentWeek!.start_date));
    }
  }

  resetWeek() {
    const dialogRef = this.dialog.open(ConfirmDialogComponent, {
      width: '320px',
    });

    dialogRef.afterClosed().subscribe((confirmed) => {
      if (confirmed && this.currentWeek) {
        this.api.resetWeek(this.currentWeek.id).subscribe(() => {
          this.loadWeek(this.currentWeek!.start_date);
          this.snackBar.open('Woche zurückgesetzt', 'OK', { duration: 2000 });
        });
      }
    });
  }

  onDateSelected(date: Date | null) {
    if (date) {
      this.loadWeek(this.toISODate(date));
    }
  }

  goToCurrentWeek() {
    this.loadWeek();
  }

  createOrShowNextWeek() {
    if (this.nextWeekExists) {
      this.loadWeek(this.nextWeekStartDate);
    } else {
      this.api.createNextWeek().subscribe({
        next: (week) => {
          this.currentWeek = week;
          this.noWeekFound = false;
          this.checkNextWeek();
          this.snackBar.open('Nächste Woche erstellt', 'OK', { duration: 2000 });
        },
        error: () => {
          this.snackBar.open('Nächste Woche existiert bereits', 'OK', { duration: 2000 });
          this.checkNextWeek();
        },
      });
    }
  }

  openDatePicker() {
    this.picker.open();
  }

  private checkNextWeek() {
    this.api.getNextWeekStatus().subscribe((status) => {
      this.nextWeekExists = status.exists;
      this.nextWeekStartDate = status.start_date;
    });
  }

  private getMonday(d: Date): Date {
    const date = new Date(d);
    const day = date.getDay();
    const diff = day === 0 ? -6 : 1 - day;
    date.setDate(date.getDate() + diff);
    date.setHours(0, 0, 0, 0);
    return date;
  }

  private toISODate(d: Date): string {
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private formatDate(d: Date): string {
    return `${String(d.getDate()).padStart(2, '0')}.${String(d.getMonth() + 1).padStart(2, '0')}.`;
  }
}
