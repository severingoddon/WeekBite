import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  imports: [
    FormsModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
  ],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss',
})
export class LoginComponent {
  password = '';
  error = '';
  hidePassword = true;

  constructor(
    private auth: AuthService,
    private router: Router,
  ) {}

  login() {
    if (!this.password) return;
    this.error = '';
    this.auth.login(this.password).subscribe({
      next: () => this.router.navigate(['/']),
      error: () => (this.error = 'Falsches Passwort'),
    });
  }
}
