# NICEGAS MQTT Architecture & Telemetry Contract

**PHASE 4.1 — MQTT ARCHITECTURE & ESP32 TELEMETRY CONTRACT**
**STATUS: ARCHITECTURE APPROVED**

## 1. Realtime Architecture

NICEGAS employs a dual-broker architecture to ensure local realtime monitoring availability even during edge server failures.

### 1.1 Broker Roles
- **Primary MQTT Broker**: Hosted on the Edge Server (Docker/Mosquitto). Responsible for data persistence (via Backend Consumer) and primary app connectivity.
- **Emergency MQTT Broker**: Hosted on an independent gateway/AP-side device (Hardware-agnostic: RPi, OpenWrt, etc.). Provides a fallback path for local monitoring when the Edge Server is offline.

### 1.2 Data Flows
1. **Normal Operation**:
   - ESP32 → Primary Broker → Flutter (Realtime View)
   - Primary Broker → Backend MQTT Consumer → PostgreSQL (Persistence)
2. **Failover Mode**:
   - ESP32 → Emergency Broker → Flutter (Local Realtime Monitoring only)
   - *Note: Data persistence is unavailable during failover.*

### 1.3 Failure & Recovery Lifecycle
- **Failure**: If the Primary Broker becomes unreachable, ESP32 and Flutter switch to the Emergency Broker.
- **Recovery**: Both components periodically attempt to reconnect to the Primary Broker and switch back once it is stable.

## 2. Topic Hierarchy

`nicegas/{site_id}/{device_id}/{category}/{component}`

### 2.1 Categories
- **telemetry**: Periodic sensor data.
- **status**: Device health/connectivity (e.g., LWT).
- **command**: Control signals from App to Hardware.
- **event**: Asynchronous alerts or specific notifications.
- **server**: Infrastructure health status.

### 2.2 Topic Examples
- `nicegas/p01/d01/telemetry/digester`
- `nicegas/p01/d01/status/connection`
- `nicegas/p01/d01/command/compressor`
- `nicegas/p01/d01/event/leakage`
- `nicegas/p01/server/status`

## 3. Telemetry Payload Contract

- **Format**: JSON
- **Rules**: `site_id`, `device_id` and `component` are derived from the topic and SHOULD NOT be duplicated in the payload.

### 3.1 Canonical Payload Schema
```json
{
  "timestamp": "2026-08-14T12:00:00Z",
  "metrics": {
    "temperature": {"v": 38.5, "u": "C"},
    "pressure": {"v": 1.2, "u": "bar"}
  },
  "status": "nominal"
}
```
- `timestamp`: ISO 8601 UTC string.
- `metrics`: Dynamic object containing sensor keys.
  - `v`: Value (Number)
  - `u`: Unit (String)
- `status`: Component health string (e.g., "nominal", "fault", "warning").

## 4. QoS & Retain Policies

| Category | QoS | Retain | Reasoning |
| :--- | :--- | :--- | :--- |
| **Telemetry** | 0 or 1 | No | High volume, historical data handled by backend. |
| **Status** | 1 | Yes | Essential for LWT and new subscriber state. |
| **Events/Alerts** | 1 | No | Critical but transient; alerts are persisted in DB. |
| **Commands** | 1 or 2 | No | Ensures control signal delivery. |
| **Server Status**| 1 | Yes | Immediate awareness of backend/broker health. |

## 5. Device Identity & Timestamps

- **Identity**: ESP32 devices are identified by `device_id` (e.g., MAC or UUID). Identity must remain stable across DHCP changes.
- **Timestamps**: Must use UTC.
  - **Preferred**: ESP32-generated timestamp (requires NTP/RTC).
  - **Fallback**: Server/Broker timestamp if device time is un-synced.
  - *Implementation Note: Time synchronization mechanism to be defined in Phase 4.2.*

## 6. Last Will and Testament (LWT)

- **Topic**: `nicegas/{site_id}/{device_id}/status/connection`
- **Payload**: `{"status": "offline", "timestamp": "..."}`
- **Connect Payload**: `{"status": "online", "timestamp": "..."}` (Sent with Retain=True).

## 7. Security Baseline

- **Anonymous Access**: Prohibited in production (Development-only).
- **Authentication**: All brokers must require Username/Password.
- **TLS**: Recommended for all production deployments.
- **Secrets**: Credentials must NOT be hardcoded. Use environment variables or secure configuration.

## 8. Operator Configuration Requirements

The setup UI must support configuring two endpoints:
1. **Primary Broker**: [Host/IP], [Port], [User], [Password], [TLS Enable]
2. **Emergency Broker**: [Host/IP], [Port], [User], [Password], [TLS Enable]

## 9. Architectural Concerns

### 9.1 Offline Data Continuity
If the Edge Server is down, data persistence to PostgreSQL is interrupted.
**Unresolved Approaches**:
- ESP32 local buffering (SD/Flash).
- Gateway-level buffering.
- Backend resynchronization/replay.
*Status: Deferred to later implementation phase.*
