# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application called "Cell" that provides an interactive educational experience for exploring cell biology. The app displays various cell organelles with animations and detailed information about each component.

## Key Commands

### Running the app
```bash
flutter run
```

### Building for iOS
```bash
flutter build ios
```

### Building for Android
```bash
flutter build apk
```

### Running tests
```bash
flutter test
```

### Analyzing code
```bash
flutter analyze
```

### Formatting code
```bash
flutter format .
```

## Architecture

### State Management
The app uses BLoC (Business Logic Component) pattern with flutter_bloc for state management:
- `CellBloc`: Manages cell-related state and interactions
- `GeneralNavigationBloc`: Handles navigation between screens

### Navigation Flow
1. **SplashPage** (`lib/views/screens/splash_page/splash_page.dart`): Initial launch screen with app branding
2. **CellPage** (`lib/views/screens/cell_page/cell_page.dart`): Main interactive cell view with animations
3. **DetailsPage** (`lib/views/screens/details_page/details_page.dart`): Detailed information about selected organelles

### Key Components
- **SplashDelegate** (`lib/views/splash_delegate.dart`): Controls whether to show splash screen based on SharedPreferences
- **GeneralViewDelegate** (`lib/views/general_view_delegate.dart`): Routes to appropriate screen based on navigation state
- **Organelle Animations** (`lib/views/screens/cell_page/animations/`): Custom animations for different cell components

### Data Layer
- **Organelles Data** (`lib/data/organelles.dart`): Contains information about cell organelles
- **Organelle Model** (`lib/models/organelle.dart`): Data model for organelles

## Native Platform Configuration

### iOS Splash Screen
- LaunchScreen.storyboard: Black background with centered LaunchImage
- Located at: `ios/Runner/Base.lproj/LaunchScreen.storyboard`

### Android Splash Screen  
- launch_background.xml: Black background
- Located at: `android/app/src/main/res/drawable/launch_background.xml`

## Important Notes
- The app supports portrait orientation only
- Uses SharedPreferences to track first-time app launch
- Assets are stored in `assets/images/` directory

## BROADCAST PROTOCOL (consultant interface)
A consultant session at the Potatuhs root coordinates this game with sod_tori, Tater Dash,
and the HPG manual. Keep `~/Potatuhs/hpg/_status/cell_mobile.md` current — it is how the
consultant reads your goals/progress without interrupting you. Update it when you (1) set or
revise goals, (2) hit a milestone or blocker, (3) write/change `manual/manual-spec.json`.
Follow the schema in `~/Potatuhs/hpg/_status/README.md`. Keep it short; it is a status board,
not a devlog.
- Configuration files are in `config/` directory