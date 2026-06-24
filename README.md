# Wake Up Alarm 🔔

A Flutter alarm app that **forces you to prove you're awake** by making you find and photograph a real object before the alarm will stop.

## How it works

1. **Set an alarm** — choose time, label, repeat days, and vibration
2. **Alarm rings** — the screen wakes your device with a loud alarm
3. **Roulette picks an item** — a spinning roulette randomly lands on one of 6 household items
4. **Find it & photograph it** — use the in-app camera to take a photo of the object
5. **ML Kit labels it** — Google ML Kit image labeling runs on-device (no internet needed)
6. **Alarm stops** ✅ — only if the correct object is detected at or above the confidence threshold

---

## Tech Stack

| Feature | Package |
|---|---|
| Alarm scheduling | `alarm ^5.4.1` |
| Notifications | `flutter_local_notifications ^21.0.0` |
| Camera | `camera ^0.12.0` |
| On-device ML | `google_mlkit_image_labeling ^0.14.2` |
| Permissions | `permission_handler ^12.0.3` |
| Storage | `shared_preferences ^2.5.5` |

---

## Project Structure

```
lib/
├── main.dart                        # App entry, alarm ring listener
├── models/
│   └── alarm_model.dart             # Alarm data model
├── services/
│   ├── alarm_scheduler_service.dart # Schedule/cancel/sync alarms
│   ├── alarm_storage_service.dart   # Persist alarms to SharedPrefs
│   ├── item_selector_service.dart   # Random item picker
│   └── object_detection_service.dart # ML Kit image labeling wrapper
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

Place an `alert-alarm.wav` file in `assets/sounds/`:

```
assets/
  sounds/
    alert-alarm.wav   ← alarm sound used by the app
  images/             ← optional
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

Items use labels from [ML Kit's official label map](https://developers.google.com/ml-kit/vision/image-labeling/label-map) only — no custom or guessed labels.

| Item | Primary ML label | Also accepts |
|---|---|---|
| Laptop | `computer` | — |
| Phone | `mobile phone` | — |
| Coffee Mug | `cup` | `coffee`, `cappuccino` |
| Chair | `chair` | — |
| TV | `television` | — |
| Houseplant | `plant` | `flower`, `flowerpot` |
| Glasses | `glasses` | `sunglasses` |
| Sneakers | `shoe` | `sneakers` |
| Bag | `bag` | `handbag` |
| Pillow | `pillow` | `cushion` |

Removed items like bottle, book, pen, and watch — those words are **not** in ML Kit's default model.

To add or change items, edit `AppConstants.alarmItems` in `lib/utils/app_theme.dart`.

---

## Detection Confidence

Default threshold: **40%** (`AppConstants.detectionConfidenceThreshold`)

Adjust in `app_theme.dart` if detections are too strict or too loose.

---

## Web Support

Flutter Web has **limited support** for background alarms (browser tabs must stay open). Camera works on mobile browsers. For full functionality, use the native Android/iOS build.

---

## License

MIT
