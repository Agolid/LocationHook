# LocationHook

Android location tracking app built with Flutter. Features geofencing, background location service, and real-time notifications.

## Features

- ✅ High-precision location tracking (geolocator)
- ✅ Real-time map display (OpenStreetMap via flutter_map — no API key needed)
- ✅ Geofencing
  - Create / edit / delete geofences with custom name, coordinates & radius
  - Enter / exit detection with visual indicator
  - Enter / exit counters
- ✅ Background location service (flutter_background_service)
- ✅ Geofence notifications (flutter_local_notifications)
  - Green notification on enter
  - Red notification on exit
- ✅ Location history (last 100 points, persisted locally)
- ✅ Permission management (location, background location, notifications)

## Tech Stack

- Flutter 3.16+
- Dart 3.0+
- `geolocator` — GPS positioning
- `flutter_map` + OpenStreetMap — map display (free, no API key)
- `flutter_background_service` — background tracking
- `flutter_local_notifications` — geofence alerts
- `shared_preferences` — local persistence
- `latlong2` — coordinate math
- `uuid` — unique geofence IDs

## Build

### Prerequisites

- Flutter SDK 3.16+
- Android SDK 34
- Java 17

### Local build

```bash
flutter pub get
flutter build apk
```

### GitHub Actions

Push to `master` triggers automatic APK build. Artifact is available for download from the Actions tab.

## Usage

1. **First launch** — Grant location and notification permissions
2. **Start Tracking** — Tap the green button to begin background location tracking
3. **Add Geofence** — Tap the bookmark icon → tap + → enter name, coordinates, and radius
4. **Geofence Alerts** — You'll get notifications when entering (green) or exiting (red) a geofence
5. **Stop Tracking** — Tap the red button to stop

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/
│   ├── geofence.dart              # Geofence data model
│   └── location_point.dart        # Location history model
├── services/
│   ├── location_service.dart      # Location tracking + persistence
│   ├── geofence_service.dart      # Geofence detection (haversine)
│   └── notification_service.dart  # Local notifications
└── pages/
    ├── home_page.dart             # Main map + tracking UI
    └── geofence_page.dart         # Geofence CRUD UI
```

## Notes

- Background tracking requires "Always allow" location permission
- Android 10+ requires precise location permission for high accuracy
- Map tiles are from OpenStreetMap (free, no API key needed)
- All data is stored locally on the device

## License

MIT
