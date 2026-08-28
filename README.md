# ITENIce Bio-CNG Mobile

A Flutter application for monitoring and controlling Bio-CNG (Compressed Natural Gas) systems. This project facilitates real-time data visualization and hardware interaction through MQTT and REST APIs.

## 🚀 Technical Stack

- **Framework:** Flutter (3.12.2+)
- **State Management:** [Riverpod](https://riverpod.dev/)
- **Networking:** [Dio](https://pub.dev/packages/dio) for REST API
- **Communication:** [MQTT Client](https://pub.dev/packages/mqtt_client) for IoT/Hardware connectivity
- **Architecture:** Clean Architecture (Feature-based)

## 📁 Project Structure

```text
lib/
├── core/           # Core infrastructure (API, MQTT, Config)
├── features/       # Business logic and UI (Dashboard, Auth, etc.)
├── shared/         # Shared models and widgets
└── main.dart       # Entry point
```

## 🛠️ Build Instructions

This project uses environment variables via `--dart-define` to manage configurations.

### Development Build
To run the project in development mode:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.nicegas.com/v1 \
  --dart-define=MQTT_HOST=your.mqtt.broker \
  --dart-define=MQTT_PORT=1883 \
  --dart-define=ENV_NAME=development
```

### Release Build
```bash
flutter build apk \
  --dart-define=API_BASE_URL=https://prod-api.nicegas.com/v1 \
  --dart-define=MQTT_HOST=prod.mqtt.broker \
  --dart-define=MQTT_PORT=8883 \
  --dart-define=ENV_NAME=production
```

## 📈 Roadmap

### Phase 1: Project Setup (Completed)
- [x] Flutter & Riverpod Initialization
- [x] Basic Folder Structure (Core/Features/Shared)
- [x] Initial MqttService & ApiService Boilerplate

### Phase 3: Dashboard & MVP Demo (Completed)
- [x] Project & Device Management
- [x] Historical Telemetry Visualization
- [x] Alerts & Notifications
- [x] Pitch Demo Mode

### Phase 4: IoT Integration & MQTT Failover (In Progress)
- [ ] Phase 4.1: MQTT Architecture & Telemetry Contract
- [ ] Phase 4.2: ESP32 Firmware Implementation
- [ ] Phase 4.3: Flutter Realtime Failover Logic

---
*Developed for BIO CNG ITENIce System.*
