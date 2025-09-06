# Repository Guidelines

## Project Structure & Module Organization
- `lib/core`: Shared models and services (e.g., `lib/core/models/*.dart`).
- `lib/features`: Feature-first UI and logic (e.g., `lib/features/buildings/...`).
- `lib/services`: Firebase and domain services (e.g., `firebase_resident_service.dart`).
- `lib/pages`: Routed screens and simple page wrappers.
- `functions`: Firebase Cloud Functions (TypeScript → `lib/` JS on build).
- `test`: Flutter tests (e.g., `test/widget_test.dart`).
- Platform folders: `android/`, `ios/`, `web/`, `macos/`, `windows/`.

## Build, Test, and Development Commands
- Flutter setup:
  - `flutter pub get`: Install Dart/Flutter deps.
  - `flutter analyze`: Static analysis with `flutter_lints`.
  - `flutter test` or `flutter test --coverage`: Run tests (+ coverage).
  - `./run_main_app.sh` or `flutter run -t lib/main.dart`: Run main app.
  - `./run_demo.sh` or `flutter run -t lib/demo_dashboard.dart`: Demo dashboard.
  - `flutter build web|apk|ios`: Production builds.
- Cloud Functions (`functions/`):
  - `npm ci && npm run build`: Install and compile TypeScript.
  - `npm run serve`: Emulator for functions (Node 20).
  - `npm run deploy`: Deploy functions only.

## Coding Style & Naming Conventions
- Follow `analysis_options.yaml` and `flutter_lints` defaults.
- Dart: 2-space indent; file names `snake_case.dart`; classes `PascalCase`; members `camelCase`.
- Organize by feature (`lib/features/<domain>/...`) and keep shared types in `lib/core`.

## Testing Guidelines
- Use `flutter_test` for widget/unit tests; place in `test/` mirroring source paths (e.g., `test/features/...`).
- Preferred names: `<subject>_test.dart`.
- Aim to cover services and critical UI flows; run `flutter test` locally before PRs.

## Commit & Pull Request Guidelines
- Commits: imperative mood; concise scope (e.g., `feat(buildings): add unit list`).
- PRs: include description, linked issues, test plan, and screenshots for UI changes.
- Keep diffs scoped by feature; update docs when behavior changes.

## Security & Configuration
- Do not commit secrets. Web Firebase keys in `lib/firebase_options.dart` are public but treat other credentials as sensitive.
- Use emulators (`firebase.json`) for local dev; review `firestore.rules` before schema changes.
- Avoid editing generated files directly; document required env/config in READMEs.

## Quick Links
- `PROJECT_OVERVIEW.md`: High-level architecture and goals.
- `SETUP_INSTRUCTIONS.md`: Local environment and tooling setup.
- `FIREBASE_SETUP.md`: FlutterFire configuration and emulator usage.
- `FIREBASE_INTEGRATION.md`: How Firebase services and Functions integrate.
- `MULTI_TENANT_IMPLEMENTATION.md`: Tenancy model and data access rules.
- `WEB_TESTING.md`: Building and testing the web target.
- `RESIDENT_MANAGEMENT_README.md`: Resident workflows, forms, and data model.
- `firestore.rules`: Firestore security rules for multi-tenant access.
 - `FIREBASE_FEATURES_SUMMARY.md`: Enabled Firebase capabilities and usage.
 - `APPLICATION_STATUS.md`: Current state, fixes, and open items.
