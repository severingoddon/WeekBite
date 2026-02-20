import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatListModule } from '@angular/material/list';
import { MatDividerModule } from '@angular/material/divider';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-invite',
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
  templateUrl: './invite.component.html',
  styleUrl: './invite.component.scss',
})
export class InviteComponent implements OnInit {
  members: { id: number; email: string }[] = [];
  newEmail = '';

  constructor(private api: ApiService) {}

  ngOnInit() {
    this.loadMembers();
  }

  loadMembers() {
    this.api.getMembers().subscribe((m) => (this.members = m));
  }

  addMember() {
    const email = this.newEmail.trim();
    if (!email) return;
    this.api.addMember(email).subscribe({
      next: () => {
        this.newEmail = '';
        this.loadMembers();
      },
    });
  }

  removeMember(id: number) {
    this.api.removeMember(id).subscribe(() => this.loadMembers());
  }
}
