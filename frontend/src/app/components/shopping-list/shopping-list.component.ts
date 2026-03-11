import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatListModule } from '@angular/material/list';
import { MatDividerModule } from '@angular/material/divider';
import { MatDialog } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { ApiService } from '../../services/api.service';
import { ShoppingItem } from '../../models/menu.model';
import { ConfirmClearDialogComponent } from './confirm-clear-dialog.component';

@Component({
  selector: 'app-shopping-list',
  imports: [
    FormsModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    MatListModule,
    MatDividerModule,
  ],
  templateUrl: './shopping-list.component.html',
  styleUrl: './shopping-list.component.scss',
})
export class ShoppingListComponent implements OnInit {
  items: ShoppingItem[] = [];
  newName = '';
  newQuantity = '';
  editingId: number | null = null;
  editName = '';
  editQuantity = '';

  constructor(private api: ApiService, private dialog: MatDialog, private snackBar: MatSnackBar) {}

  ngOnInit() {
    this.loadItems();
  }

  loadItems() {
    this.api.getShoppingItems().subscribe((items) => (this.items = items));
  }

  addItem() {
    const name = this.newName.trim();
    if (!name) return;
    if (this.items.some((i) => i.name.toLowerCase() === name.toLowerCase())) return;
    this.api.addShoppingItem({ name, quantity: this.newQuantity.trim() }).subscribe(() => {
      this.newName = '';
      this.newQuantity = '';
      this.loadItems();
    });
  }

  startEdit(item: ShoppingItem) {
    this.editingId = item.id;
    this.editName = item.name;
    this.editQuantity = item.quantity;
  }

  cancelEdit() {
    this.editingId = null;
  }

  saveEdit(id: number) {
    const name = this.editName.trim();
    if (!name) return;
    this.api.updateShoppingItem(id, { name, quantity: this.editQuantity.trim() }).subscribe(() => {
      this.editingId = null;
      this.loadItems();
    });
  }

  toggleItem(item: ShoppingItem) {
    this.api.toggleShoppingItem(item.id).subscribe((updated) => {
      item.checked = updated.checked;
    });
  }

  deleteItem(id: number) {
    this.api.deleteShoppingItem(id).subscribe(() => this.loadItems());
  }

  clearList() {
    const dialogRef = this.dialog.open(ConfirmClearDialogComponent, { width: '320px' });
    dialogRef.afterClosed().subscribe((confirmed) => {
      if (confirmed) {
        this.api.clearShoppingList().subscribe(() => {
          this.loadItems();
          this.snackBar.open('Einkaufsliste geleert', 'OK', { duration: 2000 });
        });
      }
    });
  }
}
