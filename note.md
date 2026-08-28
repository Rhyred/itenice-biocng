How to Run
•
Android Emulator: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
•
Web: flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000

flutter run -d 10DC93007H0005N --dart-define=DEMO_MODE=true

flutter build apk --release --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://192.168.159.2:8000

flutter run -d 10DC93007H0005N --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://192.168.159.2:8000