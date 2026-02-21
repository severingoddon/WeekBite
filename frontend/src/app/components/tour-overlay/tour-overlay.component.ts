import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subscription, combineLatest } from 'rxjs';
import { TourService, TourStep } from '../../services/tour.service';

@Component({
  selector: 'app-tour-overlay',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './tour-overlay.component.html',
  styleUrl: './tour-overlay.component.scss',
})
export class TourOverlayComponent implements OnInit, OnDestroy {
  active = false;
  step: TourStep | null = null;
  stepIndex = 0;
  totalSteps = 0;

  // Spotlight rect (element position)
  spotRect = { top: 0, left: 0, width: 0, height: 0 };
  // Tooltip position
  tooltipStyle: Record<string, string> = {};
  // Arrow SVG path
  arrowPath = '';
  arrowViewBox = '0 0 100 100';
  arrowStyle: Record<string, string> = {};

  private sub!: Subscription;

  constructor(private tour: TourService) {}

  ngOnInit() {
    this.sub = combineLatest([
      this.tour.active$,
      this.tour.currentIndex$,
      this.tour.steps$,
    ]).subscribe(([active, index, steps]) => {
      this.active = active;
      this.totalSteps = steps.length;
      this.stepIndex = index;
      if (active && index >= 0 && index < steps.length) {
        this.step = steps[index];
        // Small delay to ensure DOM is ready
        setTimeout(() => this.positionOverlay(), 50);
      } else {
        this.step = null;
      }
    });
  }

  ngOnDestroy() {
    this.sub?.unsubscribe();
  }

  next() {
    this.tour.nextStep();
  }

  skip() {
    this.tour.endTour();
  }

  private positionOverlay() {
    if (!this.step) return;
    const el = document.querySelector(this.step.selector) as HTMLElement;
    if (!el) return;

    // Scroll element into view
    el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });

    // Wait for scroll to finish
    setTimeout(() => this.calculatePositions(el), 300);
  }

  private calculatePositions(el: HTMLElement) {
    if (!this.step) return;
    const rect = el.getBoundingClientRect();
    const pad = 8;

    this.spotRect = {
      top: rect.top - pad,
      left: rect.left - pad,
      width: rect.width + pad * 2,
      height: rect.height + pad * 2,
    };

    const tooltipWidth = 280;
    const tooltipHeight = 140; // estimate
    const arrowLen = 50;
    const gap = 16;
    const pos = this.step.position;

    let tx: number, ty: number;
    let ax: number, ay: number, aw: number, ah: number;

    if (pos === 'bottom') {
      tx = rect.left + rect.width / 2 - tooltipWidth / 2;
      ty = rect.bottom + pad + arrowLen + gap;
      ax = rect.left + rect.width / 2 - 30;
      ay = rect.bottom + pad;
      aw = 60;
      ah = arrowLen + gap;
      this.arrowPath = this.handDrawnArrowDown();
      this.arrowViewBox = '0 0 60 70';
    } else if (pos === 'top') {
      tx = rect.left + rect.width / 2 - tooltipWidth / 2;
      ty = rect.top - pad - arrowLen - gap - tooltipHeight;
      ax = rect.left + rect.width / 2 - 30;
      ay = rect.top - pad - arrowLen - gap;
      aw = 60;
      ah = arrowLen + gap;
      this.arrowPath = this.handDrawnArrowUp();
      this.arrowViewBox = '0 0 60 70';
    } else if (pos === 'right') {
      tx = rect.right + pad + arrowLen + gap;
      ty = rect.top + rect.height / 2 - tooltipHeight / 2;
      ax = rect.right + pad;
      ay = rect.top + rect.height / 2 - 25;
      aw = arrowLen + gap;
      ah = 50;
      this.arrowPath = this.handDrawnArrowRight();
      this.arrowViewBox = '0 0 70 50';
    } else {
      // left
      tx = rect.left - pad - arrowLen - gap - tooltipWidth;
      ty = rect.top + rect.height / 2 - tooltipHeight / 2;
      ax = rect.left - pad - arrowLen - gap;
      ay = rect.top + rect.height / 2 - 25;
      aw = arrowLen + gap;
      ah = 50;
      this.arrowPath = this.handDrawnArrowLeft();
      this.arrowViewBox = '0 0 70 50';
    }

    // Clamp tooltip to viewport
    tx = Math.max(12, Math.min(tx, window.innerWidth - tooltipWidth - 12));
    ty = Math.max(12, ty);

    this.tooltipStyle = {
      left: tx + 'px',
      top: ty + 'px',
      width: tooltipWidth + 'px',
    };

    this.arrowStyle = {
      left: ax + 'px',
      top: ay + 'px',
      width: aw + 'px',
      height: ah + 'px',
    };
  }

  // Hand-drawn style arrow paths with slight wobble
  private handDrawnArrowDown(): string {
    return 'M 30 2 C 28 8, 32 18, 29 28 C 27 38, 33 48, 30 58 L 22 48 M 30 58 L 38 48';
  }

  private handDrawnArrowUp(): string {
    return 'M 30 68 C 32 62, 28 52, 31 42 C 33 32, 27 22, 30 12 L 22 22 M 30 12 L 38 22';
  }

  private handDrawnArrowRight(): string {
    return 'M 2 25 C 8 23, 18 27, 28 24 C 38 22, 48 28, 58 25 L 48 17 M 58 25 L 48 33';
  }

  private handDrawnArrowLeft(): string {
    return 'M 68 25 C 62 27, 52 23, 42 26 C 32 28, 22 22, 12 25 L 22 17 M 12 25 L 22 33';
  }
}
