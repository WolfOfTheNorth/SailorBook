# Repository Guidelines

## Project Structure & Module Organization
- `apps/app_flutter/` — Flutter app (UI, controllers, services). Run and build from here.
- `crates/pdreader_core/` — Rust core (EPUB parsing/TTs stubs). Future FRB bridge target.
- `tests/playwright/` — E2E tests with Playwright (TypeScript).
- `scripts/` — Helper scripts (`setup.sh`, `test.sh`).
- Assets: `apps/app_flutter/assets/`, Web: `apps/app_flutter/web/`.

## Build, Test, and Development Commands
- Flutter setup
  - `cd apps/app_flutter && flutter pub get` — install Dart deps.
  - `flutter run -d macos` or `-d chrome` — run locally.
  - `flutter build macos` — macOS build.
  - `flutter test` — unit/widget tests.
- Playwright E2E
  - `cd tests/playwright && npm ci` — install deps.
  - `npm run install` — install browsers.
  - `npm test` — run headless; `npm run test:ui` for UI runner.
- Scripts
  - `./scripts/setup.sh` — one-time local tooling setup.
  - `./scripts/test.sh` — convenience test runner.

## Coding Style & Naming Conventions
- Dart/Flutter
  - Use `flutter analyze` and `dart format .` (analysis rules in `analysis_options.yaml`).
  - Widgets: `PascalCase`; files: `snake_case.dart`.
  - Keep functions small; prefer `const` widgets where possible.
- Rust
  - `cargo fmt` and `cargo clippy -D warnings` before pushing.
  - Modules: `snake_case`, types: `PascalCase`.
- TypeScript (tests)
  - Prefer explicit types; files `kebab-case.spec.ts`.

## Testing Guidelines
- Unit/Widget: place under `apps/app_flutter/test/` mirroring source paths.
- E2E: add under `tests/playwright/tests/` with clear scenario names.
- Run locally: Flutter (`flutter test`) and E2E (`npm test`).
- Aim for fast, deterministic tests; avoid network flakiness (mock where possible).

## Commit & Pull Request Guidelines
- Commits: concise, imperative subject; scope prefix optional (e.g., `app:`, `core:`, `e2e:`). Example: `app: enable reader for downloaded books`.
- PRs: include purpose, screenshots for UI, reproduction steps, and linked issues.
- Keep diffs focused; update docs/tests alongside code.

## Security & Configuration Tips
- macOS uses App Sandbox; files are stored via `path_provider` in the app container. No extra entitlements needed for local reads/writes.
- Do not commit secrets; environment-specific config belongs in local env or CI settings.
