# Phase 3.5 — Alerts & Notification History Implementation Plan

This plan covers the implementation of the historical alerts feature in the NICEGAS Flutter application, using the existing REST API.

## Proposed Changes

### Shared Models

#### [NEW] [alert_list_response.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/shared/models/alert_list_response.dart)
Create the `AlertListResponse` model to handle paginated alert data from the backend.

### Core API

#### [MODIFY] [api_service.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/core/api/api_service.dart)
Add `getAlerts` method to fetch alerts with optional filters for severity, status, and device ID.

### Alerts Feature

#### [NEW] [alerts_provider.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/features/alerts/presentation/providers/alerts_provider.dart)
Implement a Riverpod `AsyncNotifierProvider` for alerts, supporting pagination and filtering.

#### [NEW] [alerts_page.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/features/alerts/presentation/pages/alerts_page.dart)
Create the main Alerts UI, including the list of alerts and filter chips.

### Navigation & Device Detail

#### [MODIFY] [device_detail_page.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/features/devices/presentation/pages/device_detail_page.dart)
Add a button to navigate to the Alerts page, filtered by the current device ID.

## Verification Plan

### Automated Tests
- Unit tests for `AlertModel` and `AlertListResponse` serialization.
- Provider tests for `AlertsProvider` success, error, and pagination.
- Widget tests for `AlertsPage` rendering and filtering.

### Manual Verification
- Navigate from Device Detail to Alerts.
- Verify alerts are loaded for the specific device.
- Test severity and status filters.
- Test "Load More" pagination.
- Verify timestamp display in local format.
