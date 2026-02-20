import { Component } from '@angular/core';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-access-denied',
  imports: [MatCardModule, MatButtonModule, MatIconModule],
  template: `
    <div class="denied-container">
      <mat-card class="denied-card">
        <mat-card-content>
          <div class="icon-glow">
            <mat-icon class="denied-icon">block</mat-icon>
          </div>
          <h2 class="gradient-text">Zugang nicht freigeschaltet</h2>
          <p class="hint">
            Bitte bei <strong>severin.goddon&#64;gmail.com</strong> anfragen, um Zugang zu erhalten.
          </p>
          <button mat-flat-button class="logout-btn" (click)="logout()">
            <mat-icon>logout</mat-icon>
            Abmelden
          </button>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: `
    .denied-container {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: calc(100vh - 64px);
      padding: 16px;
      background: radial-gradient(ellipse at center, rgba(6, 182, 212, 0.08) 0%, transparent 70%);
    }

    .denied-card {
      width: 100%;
      max-width: 400px;
      background: var(--bg-card) !important;
      text-align: center;
      padding: 32px 24px;
      border-radius: var(--radius-lg) !important;
      box-shadow: var(--shadow-glow), var(--shadow-hover) !important;
      border: 1px solid var(--border-hover) !important;
    }

    .icon-glow {
      width: 72px;
      height: 72px;
      border-radius: 50%;
      background: linear-gradient(135deg, rgba(239, 68, 68, 0.15), rgba(139, 92, 246, 0.15));
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 16px;
      box-shadow: 0 0 20px rgba(239, 68, 68, 0.2);
    }

    .denied-icon {
      font-size: 36px;
      width: 36px;
      height: 36px;
      color: #ef4444;
    }

    h2 {
      margin: 0 0 12px;
      font-weight: 600;
      font-size: 1.5rem;
      letter-spacing: -0.02em;
    }

    .hint {
      color: var(--text-secondary);
      margin: 0 0 24px;
      font-size: 0.95rem;
      line-height: 1.5;
    }

    .logout-btn {
      background: linear-gradient(135deg, var(--accent-cyan), var(--accent-violet)) !important;
      color: #fff !important;
      border-radius: var(--radius-sm) !important;
    }
  `,
})
export class AccessDeniedComponent {
  constructor(private auth: AuthService) {}

  logout() {
    this.auth.logout();
  }
}
