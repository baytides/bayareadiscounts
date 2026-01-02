# Bay Navigator

A multi-platform Flutter app for discovering local discount programs and benefits available to Bay Area residents.

## Features

- Browse hundresd of discount programs across categories like food, transit, utilities, and more
- Personalized "For You" recommendations based on your eligibility
- Save favorites for quick access
- Search and filter by category, area, and eligibility groups
- Works offline with local caching
- Dark mode support

## Platforms

| Platform | Status |
|----------|--------|
| iOS | Available on TestFlight |
| Android | APK available on GitHub Releases |
| macOS | Available on GitHub Releases |
| Windows | Available on GitHub Releases |
| Linux | Available on GitHub Releases |
| Web | [baynavigator.org](https://baynavigator.org) |
| visionOS | Available on TestFlight |

## Development

### Prerequisites

- Flutter 3.38.5 or later
- Dart 3.6.0 or later

### Setup

```bash
# Clone the repository
git clone https://github.com/baytides/baynavigator.git
cd baynavigator

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Building

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release

# Web
flutter build web --release
```

### Testing

```bash
# Run tests
flutter test

# Run analyzer
flutter analyze
```

## Project Structure

```
lib/
├── config/          # Theme configuration
├── models/          # Data models
├── providers/       # State management (Provider)
├── screens/         # UI screens
├── services/        # API and platform services
├── utils/           # Utility functions
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
```

## License

This project is open source. See the license file for details.
