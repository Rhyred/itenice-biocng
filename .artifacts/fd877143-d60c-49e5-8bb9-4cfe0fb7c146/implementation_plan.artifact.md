# Phase 3.1 — Flutter → Backend Health API Integration

Establish the first communication path between the Flutter application and the FastAPI backend health endpoint.

## User Review Required

> [!IMPORTANT]
> The backend base URL is configured via `--dart-define`. For Android Emulator to reach the host machine, use `http://10.0.2.2:8000`. For web or physical devices on the same network, use the appropriate IP or `localhost`.

## Proposed Changes

### Core Infrastructure

#### [MODIFY] [app_config.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/core/config/app_config.dart)
Update default `apiBaseUrl` to `http://localhost:8000` for easier local development.

#### [MODIFY] [api_service.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/core/api/api_service.dart)
Inject `AppConfig.apiBaseUrl` into Dio options and add a `getHealth()` method.

---

### Health Feature

#### [NEW] [health_status.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/features/health/data/models/health_status.dart)
Model to represent the backend health response:
- `status` (String)
- `service` (String)
- `database` (String)

#### [NEW] [health_provider.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/features/health/presentation/providers/health_provider.dart)
Riverpod `FutureProvider` to fetch and expose the health status.

#### [NEW] [health_page.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/features/health/presentation/pages/health_page.dart)
Simple UI to display the health status and provide a retry mechanism.

---

### Application Entry Point

#### [MODIFY] [main.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/main.dart)
Update `home` to point to `HealthPage` instead of the default counter page.

## Verification Plan

### Automated Tests
- Unit test for `HealthStatus` model serialization.
- Unit test for `ApiService.getHealth` using a mocked Dio instance.
- Widget test for `HealthPage` to ensure it displays loading, success, and error states.

### Manual Verification
- Run the app (Android Emulator or Chrome) against the local backend.
- Verify that `Connected` is displayed when the backend is up.
- Stop the backend and verify that an error message is displayed.
- Restart the backend and use the retry button to verify recovery.
