PROJECT ROLE
- NICEGAS = Bio-CNG monitoring/operator platform

SOURCE OF TRUTH
- Project/device metadata → REST
- Historical telemetry → REST
- Realtime telemetry → MQTT
- Device connectivity → MQTT
- Demo data → Demo mode only

LOCKED ARCHITECTURE
- Primary MQTT = Mosquitto on Edge Server
- Emergency MQTT = independent broker
- PostgreSQL remains current DB
- API/MQTT contracts are frozen unless PM approves

DEMO MODE
- DEMO_MODE=true → simulator
- DEMO_MODE=false → real REST + real MQTT
- Never silently fallback from real mode to demo

REALTIME
- MQTT is not the historical source
- REST baseline + MQTT live overlay
- broker status != device status

SAFETY
- AI must never be sole safety mechanism
- Critical actuator interlocks remain local/deterministic

DEVELOPMENT
- Inspect before refactoring
- Preserve existing architecture
- Prefer minimal changes
- Run analyze + tests
- Do not modify unrelated files

GIT
- Do not touch main without explicit instruction
- Preserve branch boundaries
- Never discard another team's UI work to resolve conflicts