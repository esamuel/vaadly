# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Vaadly** is a multi-tenant building management platform built with Flutter and Firebase. The app serves three user types:
- **App Owners**: Platform administrators managing multiple buildings
- **Building Committees**: Building managers (customers) managing their specific buildings
- **Residents**: End users with limited access to their unit data

The app features Hebrew (RTL) as the primary language with English support.

## Essential Commands

### Flutter Development
```bash
# Run the app
flutter run

# Run on specific device
flutter run -d chrome  # Web
flutter run -d macos   # macOS

# Build
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web

# Code generation (for freezed/json_serializable)
flutter pub run build_runner build
flutter pub run build_runner watch  # Watch mode

# Tests
flutter test
flutter test test/path/to/test_file.dart  # Single test
```

### Firebase Functions
```bash
# Navigate to functions directory first
cd functions

# Install dependencies
npm ci

# Build TypeScript
npm run build

# Deploy all functions
npm run deploy

# Run emulators (from functions dir)
npm run serve

# View logs
npm run logs

# Set custom claims (from functions dir)
npm run set-claims
npm run set-committee
npm run set-platform-admin
```

### Firebase Emulators
```bash
# Run all emulators including MCP server (from root)
./scripts/run_mcp_emulator.sh

# Emulator ports:
# - Auth: 9099
# - Functions: 5002
# - Firestore: 8080
# - Storage: 9199
```

### Web Testing
```bash
# Production build
./scripts/serve_web.sh
# Access at http://localhost:8000

# Development with hot reload
./scripts/dev_web.sh

# Check server status
./scripts/web_status.sh
```

## Architecture

### Multi-Tenant Data Model

**Important**: All data is scoped under app owners. The Firestore hierarchy is:
```
/app_owners/{ownerId}/
  ├── buildings/{buildingId}/
  │   ├── units/{unitId}
  │   ├── residents/{residentId}
  │   ├── maintenance_requests/{requestId}
  │   ├── finances/{invoiceId}
  │   └── settings/
  ├── analytics/
  ├── subscriptions/
  └── system_settings/
```

**Security**: Data isolation is enforced at the Firestore rules level. Each building committee can only access their building's data.

See `docs/VAADLY_FIRESTORE_SPEC.md` for the canonical schema, security rules, and Cloud Function specifications.

### Code Structure

```
lib/
├── core/                           # Shared core functionality
│   ├── models/                    # Data models (building, user, resident, etc.)
│   ├── services/                  # Business logic services
│   │   ├── multi_tenant_auth_service.dart   # Multi-tenant auth
│   │   ├── building_service.dart
│   │   ├── resident_service.dart
│   │   └── maintenance_service.dart
│   ├── widgets/                   # Shared widgets
│   │   └── auth_wrapper.dart     # Root authentication & routing
│   └── utils/                     # Utilities
├── features/                      # Feature modules
│   ├── auth/                     # Authentication screens
│   ├── dashboards/               # Role-specific dashboards
│   │   ├── app_owner_dashboard.dart
│   │   ├── committee_dashboard.dart
│   │   └── resident_dashboard.dart
│   ├── buildings/                # Building management
│   ├── residents/                # Resident management
│   ├── maintenance/              # Maintenance system with AI integration
│   ├── finance/                  # Financial management
│   ├── payments/                 # Stripe payment integration
│   └── settings/                 # Settings screens
├── services/                     # Additional services
│   ├── multi_tenant_service.dart       # App owner/tenant operations
│   ├── firebase_*_service.dart         # Firebase-specific services
│   └── stripe_payment_service.dart
└── main.dart                     # Entry point with routing

functions/src/
├── index.ts                      # Function exports & triggers
├── classify.ts                   # AI work order classification
├── dispatch.ts                   # Work order vendor dispatch
├── ai_intake.ts                  # Hebrew NL → structured request
├── notify.ts / notify_enhanced.ts # Notifications
├── webhooks.ts                   # Payment webhooks
└── mcp.ts                        # MCP server implementation
```

### Key Architectural Patterns

1. **Multi-Tenancy**: All services use `MultiTenantService` and `MultiTenantAuthService` to ensure proper data scoping
2. **State Management**: Provider pattern (using `provider` package)
3. **Code Generation**: Uses `freezed` and `json_serializable` for models (run build_runner after model changes)
4. **Feature-Based Organization**: Each feature is self-contained with its own pages, widgets, and logic
5. **Hebrew/RTL Support**: `locale: Locale('he')`, Google Fonts (Noto Sans Hebrew), RTL-aware layouts

### Authentication Flow

1. **AuthWrapper** (`lib/core/widgets/auth_wrapper.dart`): Root widget handling authentication and routing
2. **Route Detection**: Supports `/building/{buildingCode}` and `/manage/{buildingCode}` deep links
3. **Role-Based Navigation**: Routes users to appropriate dashboards based on role (appOwner, buildingCommittee, resident)
4. **Building Context**: Uses `BuildingContextService` to manage current building scope for committee/resident sessions

### Maintenance System

The maintenance system is the most complex feature:
- **AI Classification**: Cloud Function (`classify.ts`) uses OpenAI GPT-4 to categorize issues
- **Management Modes**: Supports different vendor management modes (committee-managed, app-owner-managed, hybrid)
- **Quote System**: Multi-vendor RFQ workflow with AI recommendations
- **Cost Policies**: Configurable approval thresholds and rules
- **Vendor Pools**: Committee-specific and app-owner-shared vendor pools

Models: `lib/core/models/maintenance/` (MaintenanceRequest, Quote, VendorProfile, VendorPool, CostPolicy)

## Important Development Notes

### Firebase & Firestore
- **Always integrate new data with Firestore** (per `.cursor/rules/resident.mdc`)
- Firebase project: `vaadly-project` (configured in `firebase.json`)
- Use Firebase emulators for local development
- Multi-tenant security rules enforce data isolation

### State Management
- Services use `StreamBuilder` patterns for real-time Firestore updates
- Dashboards typically subscribe to streams in `initState()` and clean up in `dispose()`
- Example: `FirebaseBuildingService.streamBuildings()` returns `Stream<List<Building>>`

### Code Generation
After modifying any model with `@JsonSerializable` or `@freezed`:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Internationalization
- Primary language: Hebrew (RTL)
- All UI strings should support Hebrew
- Use `Directionality` widgets where needed for RTL layouts
- Google Fonts configured for Hebrew: `GoogleFonts.notoSansHebrew()`

### AI Integration
- OpenAI GPT-4 used in Cloud Functions
- AI intake function: converts Hebrew natural language maintenance requests to structured data
- Classification function: categorizes maintenance requests by type and priority
- Functions are serverless; no MCP credentials in Flutter app

### Testing
- Tests located in `test/` directory
- Run single tests: `flutter test test/path/to/test.dart`
- Model tests: `test/core/models/`
- Widget tests: `test/widget_test.dart`

## Common Workflows

### Adding a New Building Committee (App Owner)
1. Navigate to App Owner Dashboard
2. Use "Add Building" feature
3. Configure building details and generate building code
4. Share building code with committee for onboarding

### Creating a New Feature Module
1. Create directory in `lib/features/{feature_name}/`
2. Add `pages/`, `widgets/`, and feature-specific logic
3. Update routing in `main.dart` or relevant dashboard
4. Add necessary Firebase services in `lib/services/`
5. Update Firestore security rules if adding new collections

### Deploying Functions
```bash
cd functions
npm ci              # Install dependencies
npm run build       # Compile TypeScript
npm run deploy      # Deploy to Firebase
```

### Running Locally with Emulators
```bash
# Terminal 1: Start emulators (from root)
./scripts/run_mcp_emulator.sh

# Terminal 2: Run Flutter app
flutter run -d chrome
```

## MCP Server

The MCP (Model Context Protocol) server provides AI orchestration capabilities server-side:
- Located in `functions/src/mcp.ts`
- Exposes tools for AI agents to interact with building data
- Tier-based policy gating (see `policies/mcp_tier_policy.yaml`)
- Runs only server-side; Flutter app doesn't hold MCP credentials
- Started via `./scripts/run_mcp_emulator.sh` in development

## Seeding & Scripts

Development scripts in `scripts/`:
- `seed_app_owner.dart`: Create initial app owner
- `seed_data.dart`: Seed buildings, units, residents
- `seed_vendors.dart`: Populate vendor data
- `seed_committee_pool_and_settings.dart`: Configure building maintenance settings
- `migrate_*.dart`: Data migration utilities

Run with: `flutter run {script_path}`

## Project Status

Current Phase: **Phase 2 - Core Features**
- ✅ Multi-tenant architecture
- ✅ Building & resident management
- ✅ Financial management & pricing calculator
- 🔄 Maintenance system (in progress)
- 🔄 AI-powered features (in progress)
- 📋 Voting system (planned - see `vote.md`)