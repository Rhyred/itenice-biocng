# Phase 3.6 — NICEGAS MVP Dashboard Implementation Plan

This plan outlines the creation of the first MVP Dashboard for the NICEGAS project. The dashboard will provide an operational summary of a selected project, including device status, recent telemetry, and alert summaries.

## User Review Required

- **Navigation Change**: The `ProjectListPage` will now navigate to the `DashboardPage` instead of the `DeviceListPage`.
- **Project Context**: A simple `StateProvider` will be used to track the currently selected project for the dashboard's scope.

## Proposed Changes

### [Dashboard Feature]
New feature module to handle dashboard logic and UI.

#### [NEW] [dashboard_provider.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/features/dashboard/presentation/providers/dashboard_provider.dart)
- `selectedProjectProvider`: Tracks the active project.
- `dashboardDataProvider`: Aggregates data from existing providers (devices, alerts, telemetry).

#### [NEW] [dashboard_page.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/features/dashboard/presentation/pages/dashboard_page.dart)
- Main entry point for the dashboard.
- Displays Project Header, System Status (Online/Offline), Latest Telemetry, and Alert Summary.

#### [NEW] [summary_cards.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/features/dashboard/presentation/widgets/summary_cards.dart)
- Reusable UI components for status, telemetry, and alerts.

### [Projects Feature]
#### [MODIFY] [project_list_page.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/features/projects/presentation/pages/project_list_page.dart)
- Update navigation to point to `DashboardPage` instead of `DeviceListPage`.

### [API Service]
#### [MODIFY] [api_service.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/core/api/api_service.dart)
- Add `projectId` support to `getAlerts` if the backend supports it (to be verified). If not, we will handle aggregation in the provider.
- Add `getLatestTelemetry` helper if needed (uses `getTelemetry` with small limit).

## Verification Plan

### Automated Tests
- Unit tests for `dashboardDataProvider` logic (aggregation of counts).
- Widget tests for `DashboardPage` (loading, error, and data states).

### Manual Verification
1. Launch app and select a project.
2. Verify dashboard shows correct device counts.
3. Verify recent telemetry renders (if any).
4. Verify alert summary counts are correct.
5. Verify navigation to Devices, Telemetry, and Alerts works.
6. Verify Refresh button updates data.
