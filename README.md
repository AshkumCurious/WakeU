# Wake Up Alarm 🔔

A Flutter alarm app that **forces you to prove you're awake** by making you find and photograph a real object before the alarm will stop.

## How it works

1. **Set an alarm** — choose time, label, repeat days, and vibration
2. **Alarm rings** — the screen wakes your device with a loud alarm
3. **Roulette picks an item** — a spinning roulette randomly lands on one of 6 household items
4. **Find it & photograph it** — use the in-app camera to take a photo of the object
5. **ML Kit detects it** — Google ML Kit runs on-device object detection (no internet needed)
6. **Alarm stops** ✅ — only if the correct object is detected with ≥55% confidence

---

## Tech Stack

| Feature | Package |
|---|---|
| Alarm scheduling | `alarm ^4.0.2` |
| Notifications | `flutter_local_notifications ^17.2.2` |
| Camera | `camera ^0.11.0+2` |
| On-device ML | `google_mlkit_object_detection ^0.13.0` |
| Permissions | `permission_handler ^11.3.1` |
| Storage | `shared_preferences ^2.3.2` |

---

## Project Structure

```
lib/
├── main.dart                        # App entry, alarm ring listener
├── models/
│   └── alarm_model.dart             # Alarm data model
├── services/
│   ├── alarm_scheduler_service.dart # Schedule/cancel alarms
│   ├── alarm_storage_service.dart   # Persist alarms to SharedPrefs
│   ├── item_selector_service.dart   # Random item picker
│   └── object_detection_service.dart # ML Kit wrapper
├── screens/
│   ├── home_screen.dart             # Alarm list
│   ├── add_alarm_screen.dart        # Create/edit alarm
│   ├── ringing_screen.dart          # Alarm ringing + roulette
│   ├── camera_screen.dart           # Camera + detection
│   └── result_screen.dart           # Success / fail result
├── widgets/
│   └── glowing_button.dart          # GlowingButton + AlarmCard
└── utils/
    └── app_theme.dart               # Theme + AppConstants (item list)
```

---

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Add alarm sound

Place an `alarm.mp3` file in `assets/sounds/`:

```
assets/
  sounds/
    alarm.mp3   ← put your alarm sound here
  images/       ← optional
```

Then ensure `pubspec.yaml` has:
```yaml
flutter:
  assets:
    - assets/sounds/
    - assets/images/
```

### 3. Android setup

Minimum SDK is **24** (Android 7). Targets SDK **34**.

The `AndroidManifest.xml` already includes all needed permissions:
- `CAMERA`
- `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`
- `FOREGROUND_SERVICE` (for background alarm audio)
- `WAKE_LOCK` + `DISABLE_KEYGUARD` (to wake screen)

### 4. iOS setup

`Info.plist` already includes:
- `NSCameraUsageDescription`
- `UIBackgroundModes: audio` (for alarm sound)

On iOS, background alarms have limitations when the app is fully killed. The `alarm` package handles this as best as possible using `AVAudioSession`.

### 5. Run

```bash
flutter run
```

---

## Detectable Items

Items are curated to match ML Kit's base model taxonomy reliably:

| Item | ML Label |
|---|---|
| Water Bottle | `bottle` |
| Coffee Mug | `cup` |
| Book | `book` |
| Laptop | `laptop` |
| Plant | `plant` |
| Chair | `chair` |
| Shoes | `footwear` |
| Glasses | `glasses` |
| Bag | `bag` |
| Pen | `pen` |
| Watch | `watch` |
| Pillow | `pillow` |

To add or change items, edit `AppConstants.alarmItems` in `lib/utils/app_theme.dart`.

---

## Detection Confidence

Default threshold: **55%** (`AppConstants.detectionConfidenceThreshold`)

Adjust in `app_theme.dart` if detections are too strict or too loose.

---

## Web Support

Flutter Web has **limited support** for background alarms (browser tabs must stay open). Camera works on mobile browsers. For full functionality, use the native Android/iOS build.

---

## License

MIT
