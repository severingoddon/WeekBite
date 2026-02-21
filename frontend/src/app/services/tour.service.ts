import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

export interface TourStep {
  /** CSS selector of the target element to highlight */
  selector: string;
  /** Title shown in the tooltip */
  title: string;
  /** Description text */
  text: string;
  /** Preferred position of the tooltip relative to the element */
  position: 'top' | 'bottom' | 'left' | 'right';
}

@Injectable({ providedIn: 'root' })
export class TourService {
  private readonly STORAGE_PREFIX = 'weekbite_tour_seen_';

  private stepsSubject = new BehaviorSubject<TourStep[]>([]);
  private currentIndexSubject = new BehaviorSubject<number>(-1);
  private activeSubject = new BehaviorSubject<boolean>(false);

  steps$ = this.stepsSubject.asObservable();
  currentIndex$ = this.currentIndexSubject.asObservable();
  active$ = this.activeSubject.asObservable();

  get currentStep(): TourStep | null {
    const idx = this.currentIndexSubject.value;
    const steps = this.stepsSubject.value;
    return idx >= 0 && idx < steps.length ? steps[idx] : null;
  }

  get isActive(): boolean {
    return this.activeSubject.value;
  }

  /** Check if a tour has already been completed */
  hasSeenTour(tourId: string): boolean {
    return localStorage.getItem(this.STORAGE_PREFIX + tourId) === 'true';
  }

  /** Start a tour if not already seen */
  startTour(tourId: string, steps: TourStep[]): void {
    if (this.hasSeenTour(tourId) || this.isActive) return;
    // Verify at least the first step element exists
    if (steps.length === 0) return;
    const firstEl = document.querySelector(steps[0].selector);
    if (!firstEl) return;

    this.stepsSubject.next(steps);
    this.currentIndexSubject.next(0);
    this.activeSubject.next(true);
    this.currentTourId = tourId;
  }

  private currentTourId = '';

  /** Advance to the next step (skipping missing elements), or end if last */
  nextStep(): void {
    const steps = this.stepsSubject.value;
    let next = this.currentIndexSubject.value + 1;
    // Skip steps whose target element doesn't exist in the DOM
    while (next < steps.length && !document.querySelector(steps[next].selector)) {
      next++;
    }
    if (next < steps.length) {
      this.currentIndexSubject.next(next);
    } else {
      this.endTour();
    }
  }

  /** Reset all tours so they show once more */
  resetAllTours(): void {
    const keysToRemove: string[] = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key?.startsWith(this.STORAGE_PREFIX)) {
        keysToRemove.push(key);
      }
    }
    keysToRemove.forEach((k) => localStorage.removeItem(k));
  }

  /** End the tour and mark as seen */
  endTour(): void {
    if (this.currentTourId) {
      localStorage.setItem(this.STORAGE_PREFIX + this.currentTourId, 'true');
    }
    this.activeSubject.next(false);
    this.currentIndexSubject.next(-1);
    this.stepsSubject.next([]);
    this.currentTourId = '';
  }
}
