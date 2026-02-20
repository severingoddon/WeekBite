import { Component } from '@angular/core';
import { MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';

@Component({
  selector: 'app-confirm-dialog',
  imports: [MatDialogModule, MatButtonModule],
  template: `
    <h2 mat-dialog-title>Woche zurücksetzen?</h2>
    <mat-dialog-content>
      Möchtest du wirklich alle Tage leeren? Diese Aktion kann nicht rückgängig gemacht werden.
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-button (click)="dialogRef.close(false)">Abbrechen</button>
      <button mat-flat-button color="warn" (click)="dialogRef.close(true)">Ja, leeren</button>
    </mat-dialog-actions>
  `,
  styles: [`
    h2 {
      font-weight: 600;
      letter-spacing: -0.02em;
      color: var(--text-primary);
    }
    mat-dialog-content {
      color: var(--text-secondary);
    }
  `],
})
export class ConfirmDialogComponent {
  constructor(public dialogRef: MatDialogRef<ConfirmDialogComponent>) {}
}
