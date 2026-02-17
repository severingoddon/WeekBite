import { Component, Inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatChipsModule } from '@angular/material/chips';
import { MatToolbarModule } from '@angular/material/toolbar';
import { ApiService } from '../../services/api.service';
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
  ],
  templateUrl: './menu-popup.component.html',
  styleUrl: './menu-popup.component.scss',
})
export class MenuPopupComponent implements OnInit {
  menus: Menu[] = [];
  expandedMenuId: number | null = null;

  constructor(
    private api: ApiService,
    private dialogRef: MatDialogRef<MenuPopupComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { day: string },
  ) {}

  ngOnInit() {
    this.api.getMenus().subscribe((menus) => (this.menus = menus));
  }

  selectMenu(menu: Menu) {
    this.dialogRef.close(menu.id);
  }

  toggleDetails(menuId: number, event: Event) {
    event.stopPropagation();
    this.expandedMenuId = this.expandedMenuId === menuId ? null : menuId;
  }

  close() {
    this.dialogRef.close();
  }
}
