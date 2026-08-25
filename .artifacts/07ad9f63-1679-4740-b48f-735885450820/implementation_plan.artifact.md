# Phase 3.2 — Flutter Project List & Project API Integration

Implement the Project List feature, fetching data from the backend `GET /projects` endpoint and displaying it using Riverpod.

## User Review Required

> [!IMPORTANT]
> The current `ProjectModel` in `lib/shared/models/project_model.dart` matches the minimum fields required. I will add a `ProjectListResponse` model to handle the paginated response.

## Proposed Changes

### [Shared Models]

#### [NEW] [project_list_response.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/shared/models/project_list_response.dart)
Create a new model to represent the paginated response from `/projects`.

### [Core API]

#### [MODIFY] [api_service.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/core/api/api_service.dart)
Add `getProjects` method to fetch the list of projects.

### [Features - Projects]

#### [NEW] [project_provider.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/features/projects/presentation/providers/project_provider.dart)
Create a Riverpod provider to manage the project list state.

#### [NEW] [project_list_page.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/features/projects/presentation/pages/project_list_page.dart)
Create the UI for displaying the projects, including loading, error, and empty states.

### [App Entry Point]

#### [MODIFY] [main.dart](file:///G:/CORESIGHT/NICEGAS/itenice_bio_cng/lib/main.dart)
Update the home page to `ProjectListPage`.

## Verification Plan

### Automated Tests
- Create `test/shared/models/project_model_test.dart` for serialization.
- Create `test/features/projects/project_provider_test.dart` to test the provider logic with mocked `ApiService`.
- Run `flutter analyze` and `flutter test`.

### Manual Verification
- Run the backend using Docker.
- Run the Flutter app on Chrome or Android Emulator and verify the project list is displayed.
- Verify retry functionality on error.
