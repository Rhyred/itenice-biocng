# NICEGAS Environment Setup

**STATUS: APPROVED**

## 1. Configuration Strategy
NICEGAS uses `--dart-define` for compile-time environment configuration. This avoids external dependencies like `flutter_dotenv` and provides a clean way to manage environment-specific values.

## 2. Available Variables
- `API_BASE_URL`: The base URL for the REST API (default: `https://api.nicegas.com/v1`).
- `MQTT_HOST`: The MQTT broker address.
- `MQTT_PORT`: The MQTT broker port.
- `ENV_NAME`: Name of the environment (e.g., `development`, `production`).

## 3. How to Run/Build

### VS Code `launch.json`
Add the following to your `toolArgs`:
```json
"--dart-define", "API_BASE_URL=https://dev-api.nicegas.com/v1",
"--dart-define", "MQTT_HOST=broker.nicegas.com"
```

### CLI
```bash
flutter run --dart-define=API_BASE_URL=https://api.nicegas.com/v1 --dart-define=MQTT_HOST=broker.nicegas.com
```

## 4. Security
- **NEVER** commit production credentials, passwords, or private keys using `--dart-define` or in source code.
- Production secrets should be injected via CI/CD pipelines during the build process.
