How to Run
•
Android Emulator: flutter run --dart-define=API\_BASE\_URL=http://10.0.2.2:8000
•
Web: flutter run -d chrome --dart-define=API\_BASE\_URL=http://localhost:8000

flutter run -d 10DC93007H0005N --dart-define=DEMO\_MODE=true

flutter build apk --release --dart-define=DEMO\_MODE=false --dart-define=API\_BASE\_URL=http://192.168.159.2:8000

flutter run -d 10DC93007H0005N --dart-define=DEMO\_MODE=false --dart-define=API\_BASE\_URL=http://192.168.141.132:8000


flutter build apk --release `

&#x20; --dart-define=DEMO\_MODE=false `

&#x20; --dart-define=API\_BASE\_URL=http://192.168.159.2:8000 `

&#x20; --dart-define=MQTT\_PRIMARY\_HOST=192.168.159.2 `

&#x20; --dart-define=MQTT\_PRIMARY\_PORT=1883

