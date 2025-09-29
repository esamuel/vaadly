# Repository Guidelines

This guide helps contributors work efficiently in this Flutter + Firebase repository. Follow the structure, commands, and conventions below to keep changes consistent and easy to review.

## Project Structure & Module Organization
- `lib/core`: Shared models and services (e.g., `lib/core/models/*.dart`).
- `lib/features`: Feature-first UI/logic (e.g., `lib/features/buildings/...`).
- `lib/services`: Firebase/domain services (e.g., `firebase_resident_service.dart`).
- `lib/pages`: Routed screens and simple wrappers.
- `functions/`: Firebase Cloud Functions (TypeScript → built JS in `lib/`).
- `test/`: Flutter unit/widget tests.
- Platform folders: `android/`, `ios/`, `web/`, `macos/`, `windows/`.

## Build, Test, and Development Commands
- `flutter pub get`: Install Dart/Flutter dependencies.
- `flutter analyze`: Static analysis via `flutter_lints`.
- `flutter test` / `flutter test --coverage`: Run tests (+ coverage report).
- `./run_main_app.sh` or `flutter run -t lib/main.dart`: Run main app.
- `./run_demo.sh` or `flutter run -t lib/demo_dashboard.dart`: Demo dashboard.
- `flutter build web|apk|ios`: Production builds.
- In `functions/`: `npm ci && npm run build` (install + compile), `npm run serve` (emulator), `npm run deploy` (deploy functions).

## Coding Style & Naming Conventions
- Dart: 2‑space indent; follow `analysis_options.yaml` and `flutter_lints`.
- Names: files `snake_case.dart`, classes `PascalCase`, members `camelCase`.
- Organize by feature in `lib/features/<domain>/...`; share types in `lib/core`.

## Testing Guidelines
- Framework: `flutter_test` for unit and widget tests.
- Location: mirror source paths under `test/` (e.g., `test/features/...`).
- Naming: `<subject>_test.dart`.
- Run: `flutter test` locally; add critical paths and service coverage.

## Commit & Pull Request Guidelines
- Commits: imperative mood, concise scope (e.g., `feat(buildings): add unit list`).
- PRs: include description, linked issues, test plan, and screenshots for UI.
- Keep diffs scoped by feature; update docs when behavior changes.

## Security & Configuration
- Never commit secrets. `lib/firebase_options.dart` web keys are public only.
- Use Firebase emulators for local dev; review `firestore.rules` before schema changes.
- Avoid editing generated files; document required env/config in READMEs.

## Quick Links
- `PROJECT_OVERVIEW.md`, `SETUP_INSTRUCTIONS.md`, `FIREBASE_SETUP.md`, `FIREBASE_INTEGRATION.md`, `MULTI_TENANT_IMPLEMENTATION.md`, `WEB_TESTING.md`, `RESIDENT_MANAGEMENT_README.md`, `FIREBASE_FEATURES_SUMMARY.md`, `APPLICATION_STATUS.md`, `firestore.rules`.

