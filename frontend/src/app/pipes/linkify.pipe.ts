import { Pipe, PipeTransform } from '@angular/core';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';

@Pipe({ name: 'linkify', standalone: true })
export class LinkifyPipe implements PipeTransform {
  constructor(private sanitizer: DomSanitizer) {}

  transform(value: string): SafeHtml {
    if (!value) return value;
    const urlPattern = /(https?:\/\/[^\s<]+)/g;
    const escaped = value
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
    const linked = escaped.replace(
      urlPattern,
      '<a href="$1" target="_blank" rel="noopener noreferrer" class="note-link">$1</a>',
    );
    return this.sanitizer.bypassSecurityTrustHtml(linked);
  }
}
