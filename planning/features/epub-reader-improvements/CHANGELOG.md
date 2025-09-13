# EPUB Reader Improvements — CHANGELOG

## 2025-09-13 — v0.1 MVP

What shipped
- Fallback ToC when EPUB has no declared chapters (derive from content files and first heading where present).
- Internet Archive disclaimer/boilerplate filtering at HTML stage; removes accuracy lines and "Page N" markers.
- Text extraction preserves line breaks; basic pagination (word‑safe ~1800 chars per page).
- UI updates: chapter dropdown, prev/next page controls, empty‑state message.

Bug fixes
- Removed unsupported inline regex flags that caused FormatException in Dart `RegExp`.
- Hardened cleanup to avoid over‑stripping; fall back to original HTML if cleanup empties content.

Known issues
- Fallback sections can act like short pages on some IA EPUBs; ToC order may be imperfect.
- Pagination is not layout‑aware; feels like continuous splits rather than book pages.
- HTML semantics (italics, lists) and images are not rendered in text‑only view.

Planned next
- Prefer spine/NAV ToC; group by top‑level headings for better fallback.
- Replace naive pagination with scroll reading; optionally add proper pagination later.
- Adopt `epub_view` + `flutter_html` for richer rendering and positions; or wire Rust `build_manifest()` via FRB and render paragraphs.
