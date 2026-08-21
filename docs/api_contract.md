# NICEGAS MVP API Contract v1

**STATUS: APPROVED**

## 1. Global Standards
- **Base URL:** `https://api.nicegas.com/v1` (Configurable via `API_BASE_URL`)
- **Protocol:** HTTPS
- **Authentication:** JWT Bearer Token in `Authorization` header.
- **Timestamp Format:** ISO 8601 UTC (`YYYY-MM-DDTHH:mm:ssZ`).
- **Data Format:** JSON

## 2. Common Formats

### 2.1 Error Response
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Descriptive message"
  }
}
```

### 2.2 Pagination (List Endpoints)
```json
{
  "data": [],
  "meta": {
    "total_count": 150,
    "current_page": 1,
    "limit": 20,
    "total_pages": 8
  }
}
```

## 3. Endpoints

### 3.1 POST /auth/login
- **Purpose:** Authenticate and get token.
- **Auth Required:** No
- **Request Body:** `{"email": "...", "password": "..."}`
- **Success Response:** `{"token": "...", "user": {"id": "...", "name": "..."}}`

### 3.2 GET /projects
- **Purpose:** List all Bio-CNG plants.
- **Auth Required:** Yes
- **Success Response:** Paginated list of projects.

### 3.3 GET /devices
- **Purpose:** List hardware devices.
- **Auth Required:** Yes
- **Query Params:** `project_id` (optional)
- **Success Response:** Paginated list of devices.

### 3.4 GET /devices/{deviceId}
- **Purpose:** Specific device details.
- **Auth Required:** Yes
- **Success Response:** Device metadata object.

### 3.5 GET /telemetry
- **Purpose:** Historical sensor data.
- **Auth Required:** Yes
- **Query Params:** `device_id` (required), `component` (optional), `start_time` (required), `end_time` (required), `page`, `limit`.
- **Success Response:** Paginated list of telemetry entries.

### 3.6 GET /alerts
- **Purpose:** System notifications and critical events.
- **Auth Required:** Yes
- **Query Params:** `severity`, `status`, `device_id`, `page`, `limit`.
- **Success Response:** Paginated list of alerts.
