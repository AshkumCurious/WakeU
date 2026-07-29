# SnapRise

A Flutter alarm app that **forces you to prove you're awake** before the alarm will stop — either by photographing a real object, or by doing hip-bend sit-ups tracked with on-device pose detection.

## How it works

1. **Set an alarm** — choose time, label, repeat days, vibration, difficulty, and dismissal challenge
2. **Alarm rings** — the screen wakes your device with a loud alarm
3. **Challenge is revealed** — depending on the alarm setting:
   - **Object detection** — a spinning roulette lands on a household item; photograph it with the in-app camera
   - **Sit-ups** — do a random target of 2–4 standing hip bends in front of the front camera
4. **On-device ML verifies you** — Google ML Kit image labeling or pose detection (no internet needed)
5. **Alarm stops** ✅ — only after a successful detection / completed reps

---

## Tech Stack

| Feature | Package |
|---|---|
| Alarm scheduling | `alarm ^5.4.1` |
| Notifications | `flutter_local_notifications ^21.0.0` |
| Camera | `camera ^0.12.0` |
| Object labeling | `google_mlkit_image_labeling ^0.14.2` |
| Pose / sit-up tracking | `google_mlkit_pose_detection ^0.14.1` |
| Permissions | `permission_handler ^12.0.3` |
| Storage | `shared_preferences ^2.5.5` |

App version: **2.0.0** · Display name: **SnapRise**

---

## Project Structure

Flutter project lives under `app/wake_up_alarm/`.

```
app/wake_up_alarm/lib/
├── main.dart                         # App entry, alarm ring listener
├── models/
│   └── alarm_model.dart              # Alarm data (challenge flags, difficulty)
├── services/
│   ├── alarm_scheduler_service.dart  # Schedule/cancel/sync alarms
│   ├── alarm_storage_service.dart    # Persist alarms to SharedPrefs
│   ├── item_selector_service.dart    # Random item picker
│   └── object_detection_service.dart # ML Kit image labeling wrapper
├── screens/
│   ├── home_screen.dart              # Alarm list
│   ├── add_alarm_screen.dart         # Create/edit alarm + challenge mode
│   ├── ringing_screen.dart           # Alarm ringing + challenge reveal
│   ├── camera_screen.dart            # Camera + object detection
│   ├── situp_screen.dart             # Front camera + pose-based sit-ups
│   └── result_screen.dart            # Success / fail result
├── widgets/
│   └── glowing_button.dart           # GlowingButton + AlarmCard
└── utils/
    └── app_theme.dart                # Theme + AppConstants (item list)
```

---

## Setup

### 1. Install dependencies

```bash
cd app/wake_up_alarm
flutter pub get
```

### 2. Alarm sounds

Place WAV files in `assets/sounds/` (already wired in `pubspec.yaml`):

```
assets/
  sounds/
    alert-alarm.wav
    classic_alarm.wav
    facility-alarm.wav
    sound-alert-in-hall.wav
    space-shooter.wav
  images/
```

```yaml
flutter:
  assets:
    - assets/sounds/
    - assets/images/
```

### 3. Android setup

Minimum SDK is **24** (Android 7).

Needed capabilities (camera, exact alarms, wake lock, foreground service for alarm audio) are expected via the app / plugin manifests. Grant camera and alarm permissions when prompted on device.

### 4. iOS setup

Ensure `Info.plist` includes:

- `NSCameraUsageDescription` — required for object detection and sit-up tracking
- `UIBackgroundModes: audio` — for alarm sound when backgrounded

On iOS, background alarms have limitations when the app is fully killed. The `alarm` package handles this as best as possible using `AVAudioSession`.

### 5. Run

```bash
cd app/wake_up_alarm
flutter run
```

---

## Dismissal challenges

When creating or editing an alarm, pick one challenge under **Dismissal challenge**:

| Mode | What you do | How it verifies |
|---|---|---|
| **Object detection** | Find the roulette item and take a photo | ML Kit image labeling |
| **Sit-ups** | Complete 2–4 standing hip bends | ML Kit pose detection (hip/knee landmarks) |

### Difficulty

**Difficulty** controls `minAttemptsBeforeSkip` (default **3**, range 1–10): how many failed object-detection attempts before a skip option can appear. Configured in `AppConstants` and per alarm.

---

## Detectable Items

Items use labels from [ML Kit's official label map](https://developers.google.com/ml-kit/vision/image-labeling/label-map) plus practical alternates.

| Item | Primary ML label | Also accepts |
|---|---|---|
| Laptop | `laptop` | `computer`, `macbook`, `notebook`, `personal computer` |
| Phone | `mobile phone` | `smartphone`, `telephone`, `iphone`, `gadget` |
| Coffee Mug | `cup` | `coffee`, `mug`, `cappuccino`, `coffee cup`, `drinkware` |
| Chair | `chair` | `seat`, `furniture`, `stool`, `office chair` |
| TV | `television` | `tv`, `screen`, `monitor`, `display`, `flat screen` |
| Houseplant | `plant` | `flower`, `flowerpot`, `houseplant`, `tree`, `leaf`, `vegetation` |
| Glasses | `glasses` | `sunglasses`, `eyewear`, `spectacles`, `goggles` |
| Sneakers | `sneakers` | `shoe`, `footwear`, `boot`, `athletic shoe` |
| Bag | `bag` | `handbag`, `backpack`, `tote`, `luggage`, `baggage` |
| Pillow | `pillow` | `cushion`, `throw pillow`, `bedding` |

To add or change items, edit `AppConstants.alarmItems` in `lib/utils/app_theme.dart`.

---

## Detection Confidence

Default object-detection threshold: **40%** (`AppConstants.detectionConfidenceThreshold`)

Adjust in `app_theme.dart` if detections are too strict or too loose.

Sit-up counting uses adaptive hip/knee position thresholds on the front camera (standing bend → down → stand).

---

## Web Support

Flutter Web has **limited support** for background alarms (browser tabs must stay open). Camera works on mobile browsers. For full functionality, use the native Android/iOS build.

---

## License

MIT
