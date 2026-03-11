import { Component, ElementRef, OnInit, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatChipsModule } from '@angular/material/chips';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatDividerModule } from '@angular/material/divider';
import { ApiService } from '../../services/api.service';
import { Menu, MenuCreate } from '../../models/menu.model';
import { LinkifyPipe } from '../../pipes/linkify.pipe';

@Component({
  selector: 'app-menu-management',
  imports: [
    CommonModule,
    FormsModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatInputModule,
    MatFormFieldModule,
    MatChipsModule,
    MatSnackBarModule,
    MatDividerModule,
    LinkifyPipe,
  ],
  templateUrl: './menu-management.component.html',
  styleUrl: './menu-management.component.scss',
})
export class MenuManagementComponent implements OnInit {
  @ViewChild('formCard', { read: ElementRef }) formCard!: ElementRef;

  menus: Menu[] = [];
  editingMenu: Menu | null = null;

  menuTitle = '';
  ingredientInput = '';
  ingredients: string[] = [];
  menuNote = '';
  menuEffort = 20;

  constructor(
    private api: ApiService,
    private snackBar: MatSnackBar,
  ) {}

  ngOnInit() {
    this.loadMenus();
  }

  loadMenus() {
    this.api.getMenus().subscribe((menus) => (this.menus = menus));
  }

  addIngredient() {
    const val = this.ingredientInput.trim();
    if (val && !this.ingredients.includes(val)) {
      this.ingredients.push(val);
      this.ingredientInput = '';
    }
  }

  removeIngredient(ingredient: string) {
    this.ingredients = this.ingredients.filter((i) => i !== ingredient);
  }

  saveMenu() {
    if (!this.menuTitle.trim()) return;

    const data: MenuCreate = {
      title: this.menuTitle.trim(),
      ingredients: this.ingredients,
      note: this.menuNote,
      effort_min: this.menuEffort,
    };

    if (this.editingMenu) {
      this.api.updateMenu(this.editingMenu.id, data).subscribe({
        next: () => {
          this.snackBar.open('Menu aktualisiert', 'OK', { duration: 2000 });
          this.resetForm();
          this.loadMenus();
        },
        error: (err) => this.snackBar.open(err.error?.detail || 'Fehler', 'OK', { duration: 3000 }),
      });
    } else {
      this.api.createMenu(data).subscribe({
        next: () => {
          this.snackBar.open('Menu erstellt', 'OK', { duration: 2000 });
          this.resetForm();
          this.loadMenus();
        },
        error: (err) => this.snackBar.open(err.error?.detail || 'Fehler', 'OK', { duration: 3000 }),
      });
    }
  }

  editMenu(menu: Menu) {
    this.editingMenu = menu;
    this.menuTitle = menu.title;
    this.ingredients = [...menu.ingredients];
    this.menuNote = menu.note;
    this.menuEffort = menu.effort_min;
    this.formCard.nativeElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  deleteMenu(menu: Menu) {
    this.api.deleteMenu(menu.id).subscribe(() => {
      this.snackBar.open('Menu gelöscht', 'OK', { duration: 2000 });
      if (this.editingMenu?.id === menu.id) {
        this.resetForm();
      }
      this.loadMenus();
    });
  }

  resetForm() {
    this.editingMenu = null;
    this.menuTitle = '';
    this.ingredientInput = '';
    this.ingredients = [];
    this.menuNote = '';
    this.menuEffort = 20;
  }

  importCsv(event: Event) {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      const text = (reader.result as string).replace(/^\uFEFF/, '');
      const lines = text.split(/\r?\n/).filter((l) => l.trim());

      if (lines.length < 2) {
        this.showImportError();
        input.value = '';
        return;
      }

      const header = lines[0].trim();
      const validHeaders = ['Menu;Zutaten', 'Menu;Zutaten;Notiz;Aufwand'];
      if (!validHeaders.includes(header)) {
        this.showImportError();
        input.value = '';
        return;
      }
      const hasExtendedFields = header === 'Menu;Zutaten;Notiz;Aufwand';

      const parsed: MenuCreate[] = [];
      for (let i = 1; i < lines.length; i++) {
        const row = this.parseCsvRow(lines[i]);
        if (row.length < 2) {
          this.showImportError(i + 1);
          input.value = '';
          return;
        }
        const title = row[0].trim();
        const ingredients = row[1]
          .split(',')
          .map((s) => s.trim())
          .filter((s) => s);
        const note = hasExtendedFields && row.length > 2 ? row[2].trim() : '';
        const effort_min = hasExtendedFields && row.length > 3 ? parseInt(row[3].trim(), 10) || 20 : 20;
        if (!title) {
          this.showImportError(i + 1);
          input.value = '';
          return;
        }
        parsed.push({ title, ingredients, note, effort_min });
      }

      this.importMenusSequentially(parsed, 0, 0);
      input.value = '';
    };
    reader.readAsText(file, 'utf-8');
  }

  private parseCsvRow(line: string): string[] {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
      const char = line[i];
      if (inQuotes) {
        if (char === '"' && line[i + 1] === '"') {
          current += '"';
          i++;
        } else if (char === '"') {
          inQuotes = false;
        } else {
          current += char;
        }
      } else {
        if (char === '"') {
          inQuotes = true;
        } else if (char === ';') {
          result.push(current);
          current = '';
        } else {
          current += char;
        }
      }
    }
    result.push(current);
    return result;
  }

  private importMenusSequentially(items: MenuCreate[], index: number, successCount: number) {
    if (index >= items.length) {
      this.snackBar.open(`${successCount} Menus importiert`, 'OK', { duration: 3000 });
      this.loadMenus();
      return;
    }
    this.api.createMenu(items[index]).subscribe({
      next: () => this.importMenusSequentially(items, index + 1, successCount + 1),
      error: () => {
        this.snackBar.open(`"${items[index].title}" übersprungen (existiert bereits)`, 'OK', { duration: 2000 });
        this.importMenusSequentially(items, index + 1, successCount);
      },
    });
  }

  private showImportError(line?: number) {
    const msg = line
      ? `CSV-Fehler in Zeile ${line}. Format: Menu;Zutaten;Notiz;Aufwand`
      : 'Ungültiges CSV-Format. Erste Zeile muss "Menu;Zutaten" oder "Menu;Zutaten;Notiz;Aufwand" sein';
    this.snackBar.open(msg, 'OK', { duration: 8000 });
  }

  exportCsv() {
    const header = 'Menu;Zutaten;Notiz;Aufwand';
    const rows = this.menus.map((m) => {
      const title = m.title.replace(/"/g, '""');
      const ingredients = m.ingredients.join(', ').replace(/"/g, '""');
      const note = (m.note || '').replace(/"/g, '""');
      return `"${title}";"${ingredients}";"${note}";${m.effort_min}`;
    });
    const csv = [header, ...rows].join('\n');
    const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'menus.csv';
    link.click();
    URL.revokeObjectURL(url);
  }
}
