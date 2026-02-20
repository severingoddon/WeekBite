import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatListModule } from '@angular/material/list';
import { MatDividerModule } from '@angular/material/divider';
import { MatMenuModule } from '@angular/material/menu';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { ApiService } from '../../services/api.service';
import { AuthService, UserInfo } from '../../services/auth.service';
import { Family } from '../../models/menu.model';

@Component({
  selector: 'app-family-management',
  imports: [
    CommonModule,
    FormsModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    MatListModule,
    MatDividerModule,
    MatMenuModule,
    MatSnackBarModule,
  ],
  templateUrl: './family-management.component.html',
  styleUrl: './family-management.component.scss',
})
export class FamilyManagementComponent implements OnInit {
  families: Family[] = [];
  newFamilyName = '';
  inviteEmails: { [familyId: number]: string } = {};
  editingFamilyId: number | null = null;
  editFamilyName = '';
  user: UserInfo | null = null;

  constructor(
    private api: ApiService,
    private auth: AuthService,
    private snackBar: MatSnackBar,
  ) {}

  ngOnInit() {
    this.loadData();
  }

  loadData() {
    this.auth.getMe().subscribe((u) => {
      this.user = u;
      this.families = u.families;
    });
  }

  createFamily() {
    const name = this.newFamilyName.trim();
    if (!name) return;
    this.api.createFamily({ name }).subscribe({
      next: () => {
        this.newFamilyName = '';
        this.snackBar.open('Familie erstellt', 'OK', { duration: 2000 });
        this.loadData();
      },
      error: (err) => this.snackBar.open(err.error?.detail || 'Fehler', 'OK', { duration: 3000 }),
    });
  }

  startRename(family: Family) {
    this.editingFamilyId = family.id;
    this.editFamilyName = family.name;
  }

  saveRename(family: Family) {
    const name = this.editFamilyName.trim();
    if (!name) return;
    this.api.updateFamily(family.id, { name }).subscribe({
      next: () => {
        this.editingFamilyId = null;
        this.snackBar.open('Familie umbenannt', 'OK', { duration: 2000 });
        this.loadData();
      },
      error: (err) => this.snackBar.open(err.error?.detail || 'Fehler', 'OK', { duration: 3000 }),
    });
  }

  cancelRename() {
    this.editingFamilyId = null;
  }

  deleteFamily(family: Family) {
    this.api.deleteFamily(family.id).subscribe({
      next: () => {
        this.snackBar.open('Familie gelöscht', 'OK', { duration: 2000 });
        this.loadData();
      },
      error: (err) => this.snackBar.open(err.error?.detail || 'Fehler', 'OK', { duration: 3000 }),
    });
  }

  leaveFamily(family: Family) {
    if (!this.user) return;
    const userId = this.getUserId(family);
    if (!userId) return;
    this.api.removeFamilyMember(family.id, userId).subscribe({
      next: () => {
        this.snackBar.open('Familie verlassen', 'OK', { duration: 2000 });
        this.loadData();
      },
      error: (err) => this.snackBar.open(err.error?.detail || 'Fehler', 'OK', { duration: 3000 }),
    });
  }

  inviteMember(family: Family) {
    const email = (this.inviteEmails[family.id] || '').trim();
    if (!email) return;
    this.api.inviteToFamily(family.id, email).subscribe({
      next: (res) => {
        this.inviteEmails[family.id] = '';
        this.snackBar.open(res.detail || 'Einladung gesendet', 'OK', { duration: 2000 });
        this.loadData();
      },
      error: (err) => this.snackBar.open(err.error?.detail || 'Fehler', 'OK', { duration: 3000 }),
    });
  }

  removeMember(family: Family, userId: number) {
    this.api.removeFamilyMember(family.id, userId).subscribe({
      next: () => {
        this.snackBar.open('Mitglied entfernt', 'OK', { duration: 2000 });
        this.loadData();
      },
      error: (err) => this.snackBar.open(err.error?.detail || 'Fehler', 'OK', { duration: 3000 }),
    });
  }

  isCreator(family: Family): boolean {
    return this.getUserId(family) === family.created_by;
  }

  private getUserId(family: Family): number {
    if (!this.user) return 0;
    const member = family.members.find((m) => m.email === this.user!.email);
    return member ? member.user_id : 0;
  }

  isActive(family: Family): boolean {
    return this.user?.active_family_id === family.id;
  }

  setActive(family: Family) {
    this.api.switchContext(family.id).subscribe(() => {
      this.loadData();
      this.snackBar.open(`Kontext: ${family.name}`, 'OK', { duration: 2000 });
    });
  }

  setPrivate() {
    this.api.switchContext(null).subscribe(() => {
      this.loadData();
      this.snackBar.open('Kontext: Privat', 'OK', { duration: 2000 });
    });
  }
}
