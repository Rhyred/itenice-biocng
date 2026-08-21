# NICEGAS MQTT Convention

**STATUS: APPROVED**

## 1. Topic Hierarchy
`nicegas/{site_id}/{device_id}/{category}/{component}`

### Categories
- **telemetry**: Periodic sensor data.
- **status**: Device health/connectivity (e.g., LWT).
- **command**: Control signals from App to Hardware.
- **event**: Asynchronous alerts or specific notifications.

## 2. Topic Examples
- `nicegas/p01/d01/telemetry/digester`
- `nicegas/p01/d01/status/connection`
- `nicegas/p01/d01/command/compressor`
- `nicegas/p01/d01/event/leakage`

## 3. Telemetry Payload Contract
- **Strategy:** Component-level topics with multi-metric payloads.
- **Rules:** `device_id` and `component` are derived from the topic and MUST NOT be duplicated in the payload.

### Example Payload
Topic: `nicegas/p01/d01/telemetry/digester`

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

- `v`: Value
- `u`: Unit
