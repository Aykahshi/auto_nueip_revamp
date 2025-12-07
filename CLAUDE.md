# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Auto Nueip is a Flutter application that implements NUEIP functionality using Clean Architecture with feature-first approach. The app uses Joker State for state management and follows SOLID principles.

## Development Commands

### Basic Commands
```bash
# Install Flutter SDK version managed by FVM
fvm use stable
fvm flutter --version

# Get dependencies
make get
# or
fvm flutter pub get

# Clean and reinstall dependencies
make clean_get

# Run code generation (required after model changes)
make code
# or
fvm dart run build_runner build --delete-conflicting-outputs

# Run code generation in watch mode during development
make code_watch
# or
fvm dart run build_runner watch --delete-conflicting-outputs

# Run the app
fvm flutter run

# Build Android APK
make build
# or
fvm flutter build apk --split-per-abi
```

### Testing
```bash
# Run unit tests
make test
# or
fvm flutter test
```

### Upgrading Dependencies
```bash
# Upgrade Flutter packages
make upgrade
# or
fvm flutter pub upgrade
```

## Architecture Overview

The project follows **Clean Architecture** with a **feature-first** approach:

### Core Structure
- **`lib/main.dart`**: App entry point, initializes all dependencies using Circus (DI container from Joker State)
- **`lib/index.dart`**: Root app widget with theme configuration and router setup
- **`lib/core/`**: Shared utilities, network, theme, router, and extensions
- **`lib/features/`**: Feature modules organized by functionality

### Key Architectural Patterns

#### 1. Dependency Injection (DI)
- Uses **Circus** from Joker State for DI
- All dependencies registered in `main.dart`'s `_initDependencies()` method
- Services registered as contracts, repositories as implementations with aliases

#### 2. State Management
- **Joker State** for reactive state management
- Each feature has presenters that manage state using Jokers
- State is immutable and updated through `trick()` method

#### 3. Routing
- **Auto Route** for declarative navigation
- Route guards implemented (AuthGuard for authentication)
- Nested routes for tab-based navigation
- Routes must be regenerated after changes: `make code`

#### 4. Feature Structure
Each feature follows Clean Architecture:
```
feature/
├── data/
│   ├── models/           # Data transfer objects
│   ├── repositories/     # Repository implementations
│   └── services/         # API/data services
├── domain/
│   ├── entities/         # Business objects
│   └── repositories/     # Repository interfaces
└── presentation/
    ├── presenters/       # State management (like ViewModels)
    ├── screens/          # UI pages
    └── widgets/          # Reusable UI components
```

### Key Features
- **nueip**: Core API integration and data repository
- **login**: Authentication with session management
- **home**: Main screens with clock in/out functionality
- **calendar**: Attendance history with calendar view
- **form**: Leave application and history management
- **setting**: User profile and app configuration
- **holiday**: Holiday data for calendar integration

## Important Implementation Details

### Code Generation
The project uses several code generation packages:
- `auto_route_generator`: Generates router code (`app_router.gr.dart`)
- `freezed`: Generates immutable classes and copyWith methods
- `json_serializable`: Generates JSON serialization code

Always run `make code` after:
- Modifying models with @freezed annotations
- Adding/removing routes in `AppRouter`
- Changing JSON serialization in models

### API Configuration
- Base URLs and endpoints in `lib/core/config/apis.dart`
- Custom Dio interceptors for authentication and logging
- Cookie management for session persistence

### Responsive Design
- Uses `flutter_screenutil` for responsive scaling
- Design size: 393x852 (iPhone 14 dimensions)
- All sizes must use `.w`, `.h`, `.sp` extensions from ScreenUtil

### Theme Management
- Custom theme implementation in `lib/core/theme/app_theme.dart`
- Theme mode persisted in LocalStorage
- Animated theme transitions

## Testing Strategy
- Unit tests located in `test/` directory
- Widget tests use Flutter's testing framework
- Presenters should be tested independently (mock repositories)

## Common Pitfalls

1. **Forgetting to run code generation** after model/route changes
2. **Not using FVM** for Flutter version management
3. **Hardcoding sizes** instead of using ScreenUtil extensions
4. **Not registering new dependencies** in main.dart
5. **Direct API calls in UI** instead of using repositories

## Development Workflow

1. Create feature branch
2. Make changes to models/entities
3. Run `make code` to regenerate files
4. Implement presenters and UI
5. Test with `make test`
6. Build APK to verify: `make build`