# TourVN Mobile App

Flutter mobile app for TourVN - AI-powered Vietnam travel planning for Gen Z.

## Project Structure

This project follows **Feature-First Clean Architecture** for maintainability and scalability.

### Core (`lib/core/`)

Shared utilities and components used across all features:

- **theme/**: Design tokens (colors, typography, spacing, gradients)
- **widgets/**: Reusable UI components (GlassCard, GradientButton, etc.)
- **utils/**: Helper functions, constants, validators
- **router/**: Navigation configuration (go_router)
- **exceptions/**: Custom exception handling (AppException)

### Features (`lib/features/`)

Feature modules organized with Clean Architecture (3 layers):

#### Feature List:
- **auth/**: User authentication (Google/Facebook OAuth, Anonymous)
- **home/**: Home screen with Bento Grid content feed
- **destination/**: Destination browsing and location discovery
- **trip/**: Trip planning and management (Day picker, Visual planner)
- **review/**: Review browsing and engagement
- **admin/**: Admin dashboard for content management (Web)

#### Clean Architecture Layers:

Each feature has 3 layers:

1. **data/**: Repositories, data sources, API/Firestore integration
2. **domain/**: Business logic, entities, use cases (no Flutter deps)
3. **presentation/**: UI screens, widgets, Riverpod providers

### Getting Started

```bash
# Install dependencies
flutter pub get

# Run on iOS Simulator
flutter run -d ios

# Run on Android Emulator
flutter run -d android
```

## Technology Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod 3.2.0
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Navigation**: go_router
- **Architecture**: Feature-First Clean Architecture

## Development Guidelines

- Follow feature-first structure: All feature code goes in `features/{feature_name}/`
- Use Clean Architecture layers: `data/`, `domain/`, `presentation/`
- Naming: Classes PascalCase, files snake_case, folders snake_case
- Error handling: Use centralized `AppException` pattern
- State management: Riverpod AsyncNotifier for async operations

For detailed architecture decisions, see [Architecture Document](_bmad-output/planning-artifacts/architecture.md).

## Firebase Configuration

This project uses Firebase for backend services:

- **Firebase Project**: tourvn-mobile-2026
- **Services**: Authentication, Firestore, Cloud Storage
- **Configuration**: Auto-generated via FlutterFire CLI

## Security

**Important**: Read `SECURITY.md` to understand Firebase API keys.

Configuration details: `docs/FIREBASE_SECURITY_SETUP.md`

## Platform Support

- ✅ Android (API 26+)
- ✅ iOS (13+)
- ❌ Web (Admin dashboard only, not mobile app)

## Build Commands

```bash
# Run debug build
flutter run

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Analyze code
flutter analyze
```

## Documentation

- `SECURITY.md` - Security policy
- `docs/FIREBASE_SECURITY_SETUP.md` - Firebase setup guide
- `.env.example` - Environment variables template
- `_bmad-output/planning-artifacts/` - Project planning documents

## License

Copyright © 2026 TourVN

---
**Project**: TourVN Mobile App  
**Firebase**: tourvn-mobile-2026  
**Repository**: https://github.com/XuanNguyenNB/tourvnapp
