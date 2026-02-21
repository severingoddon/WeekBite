import { Component, Inject, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatChipsModule } from '@angular/material/chips';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { FormsModule } from '@angular/forms';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { ApiService } from '../../services/api.service';
import { TourService } from '../../services/tour.service';
import { Menu } from '../../models/menu.model';

@Component({
  selector: 'app-menu-popup',
  imports: [
    CommonModule,
    MatDialogModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatChipsModule,
    MatToolbarModule,
    MatFormFieldModule,
    MatInputModule,
    FormsModule,
    MatSnackBarModule,
  ],
  templateUrl: './menu-popup.component.html',
  styleUrl: './menu-popup.component.scss',
})
export class MenuPopupComponent implements OnInit, OnDestroy {
  menus: Menu[] = [];
  filteredMenus: Menu[] = [];
  searchQuery = '';
  expandedMenuId: number | null = null;
  sortByEffort = false;

  constructor(
    private api: ApiService,
    private dialogRef: MatDialogRef<MenuPopupComponent>,
    private snackBar: MatSnackBar,
    private tour: TourService,
    @Inject(MAT_DIALOG_DATA) public data: { day: string },
  ) {}

  ngOnInit() {
    this.api.getMenus().subscribe((menus) => {
      this.menus = menus;
      this.filteredMenus = menus;
    });
  }

  filterMenus() {
    const q = this.searchQuery.toLowerCase();
    let result = this.menus.filter((m) => m.title.toLowerCase().includes(q));
    if (this.sortByEffort) {
      result = [...result].sort((a, b) => a.effort_min - b.effort_min);
    }
    this.filteredMenus = result;
  }

  toggleSort() {
    this.sortByEffort = !this.sortByEffort;
    this.filterMenus();
  }

  selectMenu(menu: Menu) {
    this.dialogRef.close(menu.id);
  }

  toggleDetails(menuId: number, event: Event) {
    event.stopPropagation();
    this.expandedMenuId = this.expandedMenuId === menuId ? null : menuId;
    if (this.expandedMenuId !== null) {
      this.tryStartTour();
    }
  }

  private tryStartTour() {
    if (this.tour.hasSeenTour('menu-popup')) return;
    setTimeout(() => {
      this.tour.startTour('menu-popup', [
        {
          selector: '[data-tour="ingredient-chip"]',
          title: 'Zutat zur Einkaufsliste',
          text: 'Tippe auf eine Zutat, um sie direkt zur Einkaufsliste hinzuzufügen.',
          position: 'bottom',
        },
        {
          selector: '[data-tour="menu-select"]',
          title: 'Menu auswählen',
          text: 'Tippe auf eine Menu-Karte, um dieses Menu dem Tag zuzuweisen.',
          position: 'bottom',
        },
      ]);
    }, 350);
  }

  addToShoppingList(ingredient: string, event: Event) {
    event.stopPropagation();
    this.api.addShoppingItem({ name: ingredient, quantity: '' }).subscribe((item) => {
      if (!item.created) return;
      const ref = this.snackBar.open('Zur Einkaufsliste hinzugefügt', 'Rückgängig', { duration: 4000 });
      ref.onAction().subscribe(() => {
        this.api.deleteShoppingItem(item.id).subscribe();
      });
    });
  }

  ngOnDestroy() {
    if (this.tour.isActive) {
      this.tour.endTour();
    }
  }

  close() {
    this.dialogRef.close();
  }
}
