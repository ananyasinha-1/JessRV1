# 🤖 Rover Companion App

A Flutter Android app that acts as the **AI brain** of your ESP32 rover.  
The rover hardware stays minimal — all intelligence lives in the app.

---

## Architecture

```
┌──────────────────────────────────────────┐
│           Flutter App (Android)           │
│                                          │
│  Camera Feed ──► Perception Engine       │
│                       │                  │
│                  Memory Store            │
│                       │                  │
│               State Manager             │
│              ┌────────┴────────┐         │
│         Intent Engine   Voice Service   │
│              └────────┬────────┘         │
│             Behavior Engine             │
│                       │                  │
│              Command Service            │
└───────────────────────┼──────────────────┘
              HTTP REST (local Wi-Fi)
          ┌────────────┴──────────────┐
    rover.local                  cam.local
   (ESP32 Motor)             (ESP32-CAM MJPEG)
```

---

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── perception.dart          # PerceptionResult, BoundingBox
│   ├── rover_state.dart         # MainState, EmotionalState, Intent enums
│   ├── memory_model.dart        # Short-term rover memory
│   └── app_config.dart          # Host settings (persisted)
├── services/
│   ├── command_service.dart     # HTTP commands → rover.local
│   ├── camera_service.dart      # MJPEG stream from cam.local
│   ├── vision_service.dart      # Device camera for ML Kit frames
│   └── voice_service.dart       # STT + TTS
├── engines/
│   ├── perception_engine.dart   # Google ML Kit face + object detection
│   ├── intent_engine.dart       # Decides goal from state + perception
│   ├── behavior_engine.dart     # Maps intent → movement + emotion
│   └── state_manager.dart       # Central brain, ChangeNotifier
└── ui/
    ├── screens/
    │   ├── splash_screen.dart   # Boot sequence
    │   ├── face_screen.dart     # Main animated robot face
    │   ├── control_screen.dart  # Camera feed + D-pad
    │   └── settings_screen.dart # Network config
    └── widgets/
        ├── robot_face.dart      # Custom painted animated face
        ├── status_hud.dart      # State/emotion overlay
        ├── dpad_control.dart    # Manual drive controls
        └── camera_stream_widget.dart  # MJPEG display

firmware/
├── rover_controller/
│   └── rover_controller.ino    # ESP32 motor + servo + HTTP server
└── esp32_cam/
    └── esp32_cam.ino           # ESP32-CAM MJPEG stream only
```

---

## Quick Start

### 1. Flash the Firmware

**Rover Controller (ESP32):**
1. Open `firmware/rover_controller/rover_controller.ino` in Arduino IDE
2. Set your hotspot SSID/password
3. Flash to your ESP32
4. Wire motors per the pin comments in the file

**Camera (ESP32-CAM AI Thinker):**
1. Open `firmware/esp32_cam/esp32_cam.ino`
2. Set the same hotspot SSID/password
3. Flash via FTDI adapter (GPIO 0 to GND during flash)
4. The stream will be at `http://cam.local/stream`

### 2. Build the Flutter App

```bash
# Install dependencies
flutter pub get

# Run on connected Android device
flutter run

# Build release APK
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

### 3. Network Setup

- Enable hotspot on your phone
- Both ESP32 devices connect to it
- The app connects to `rover.local` and `cam.local` via mDNS
- If mDNS fails, set manual IPs in the app's Config screen

---

## App Behavior

### The Loop (runs every 200ms in auto mode)

```
getCameraFrame()
    → analyzeFrame()       (ML Kit: face + person detection)
    → updateMemory()       (smooth confidence, target position)
    → determineState()     (based on perception + user input)
    → decideIntent()       (FOLLOW / GREET / SEARCH / IDLE...)
    → mapToAction()        (movement direction + servo + emotion)
    → sendCommand()        (HTTP GET to rover.local)
    → updateExpression()   (animated robot face)
```

### Modes

| Mode     | Behavior |
|----------|----------|
| IDLE     | Stops, neutral face, sleepy eyes |
| MANUAL   | D-pad full control, no auto |
| TRACKING | Follows person, smooth turning |
| INTERACTING | Greets known faces, speaks |
| SEARCHING | Slow scan when target lost |
| ERROR    | Stops, shows error state |

### Emotions → Face Expressions

| Emotion | Eyes | Mouth | Glow |
|---------|------|-------|------|
| neutral | oval | slight smile | blue |
| happy | arc up | big smile | green |
| focused | triangle | tight line | blue-white |
| curious | oval + tilt | slight | cyan |
| confused | offset | wavy | red-pink |
| alert | oval | O | orange |
| sleepy | half-closed | flat | purple |

---

## Voice Commands

Say these while the mic is active (tap mic button):

| Command | Action |
|---------|--------|
| "follow me" / "track" | Switch to tracking mode |
| "stop" / "halt" | Stop all movement |
| "forward" / "go" | Drive forward (manual) |
| "back" / "reverse" | Drive backward (manual) |
| "left" / "right" | Turn (manual) |
| "look up" / "tilt up" | Servo up 20° |
| "look down" / "tilt down" | Servo down 20° |
| "manual mode" | Switch to manual |
| "auto mode" | Switch to autonomous |
| "sleep" / "rest" | Switch to idle |

---

## Rover HTTP API

Base: `http://rover.local`

```
GET /move?dir=forward    Drive forward
GET /move?dir=back       Drive backward
GET /move?dir=left       Turn left
GET /move?dir=right      Turn right
GET /move?dir=stop       Stop
GET /servo?angle=90      Set servo angle (0–180)
GET /status              JSON status response
```

Camera stream: `http://cam.local/stream` (MJPEG)

---

## Safety

- **Watchdog:** Rover stops automatically if no command received for 2 seconds
- **Manual override:** Manual mode always has highest priority
- **Connection loss:** App stops autonomous behavior and shows error state
- **Fail-safe:** On app dispose/crash, stop command is sent

---

## Dependencies

| Package | Purpose |
|---------|---------|
| provider | State management |
| http | Rover HTTP commands |
| google_mlkit_face_detection | Face detection |
| google_mlkit_object_detection | Person detection |
| camera | Device camera for ML pipeline |
| speech_to_text | Voice command recognition |
| flutter_tts | Text-to-speech for greetings |
| shared_preferences | Persist config (host settings) |
| rxdart | Stream utilities |

---

## Development Phases

- [x] Phase 1: Network connection, stream, manual control
- [x] Phase 2: Object detection, tracking, smooth turn control
- [x] Phase 3: Face detection, memory, emotional states, search behavior
- [x] Phase 4: Voice interaction, animated UI, settings persistence

---

## Pinout Reference (Rover ESP32)

| Signal | GPIO |
|--------|------|
| L_IN1 | 26 |
| L_IN2 | 27 |
| R_IN1 | 14 |
| R_IN2 | 12 |
| L_EN (PWM) | 25 |
| R_EN (PWM) | 33 |
| Servo | 13 |

Adjust to match your motor driver wiring.
