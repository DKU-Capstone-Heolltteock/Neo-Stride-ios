# Neo-Stride iOS App Development Plan

> For Hermes: Use `subagent-driven-development` if this plan is implemented task-by-task.

Date: 2026-05-04

Goal: Build a separate native iOS app that matches the current Neo-Stride Android app's core user flows while sharing the same Spring Boot backend and API contract.

Architecture: Use SwiftUI-first native iOS implementation with MVVM, async/await networking, Codable DTOs, Keychain-backed auth storage, CoreLocation for running tracking, and MapKit for route display. Keep the Android app unchanged; the iOS app consumes the shared backend API documented in `/home/yoonhyeon/projects/Neo-Stride/docs/frontend-api-spec.md`.

Tech Stack: Swift, SwiftUI, Combine or Swift Concurrency, URLSession, Codable, Keychain Services, CoreLocation, MapKit, XCTest, XCUITest, optional WatchKit target later.

Repositories:
- Android source of truth: `/home/yoonhyeon/projects/Neo-Stride/Neo-Stride`
- Backend/API spec: `/home/yoonhyeon/projects/Neo-Stride/Neo-Stride-BE`, `/home/yoonhyeon/projects/Neo-Stride/docs/frontend-api-spec.md`
- iOS target repo: `/home/yoonhyeon/projects/Neo-Stride/Neo-Stride-ios`

---

## 1. Android Baseline Summary

The current Android project is a Java/XML app with these core areas:

1. Auth
   - Files:
     - `Neo-Stride/app/src/main/java/com/neostride/app/feature/auth/LoginActivity.java`
     - `Neo-Stride/app/src/main/java/com/neostride/app/feature/auth/SignupActivity.java`
     - `Neo-Stride/app/src/main/java/com/neostride/app/feature/auth/repository/AuthRepository.java`
     - `Neo-Stride/app/src/main/java/com/neostride/app/feature/auth/api/AuthApi.java`
   - API:
     - `POST /api/auth/login`
     - `POST /api/auth/signup`
   - iOS implication:
     - Implement login/signup first because all running/coaching APIs depend on user identity and token handling.
     - Fix Android's current token-storage mismatch in iOS from the beginning: store token and user_id in one `AuthStore` abstraction.

2. Main navigation
   - File: `Neo-Stride/app/src/main/java/com/neostride/app/activity/MainActivity.java`
   - Tabs:
     - Running
     - Record
     - Coaching
     - Community as separate activity
     - Notification via top icon
     - Profile/logout popup
   - iOS implication:
     - Use `TabView` for Running, Record, Coaching, Community.
     - Use navigation toolbar buttons for notification/profile.

3. Running
   - File: `Neo-Stride/app/src/main/java/com/neostride/app/feature/running/RunningFragment.java`
   - Android dependencies:
     - Google Maps
     - FusedLocationProviderClient
     - Runtime fine/coarse location permissions
   - Main behavior:
     - Show map
     - Request/move to current location
     - Free running start/stop/pause
     - Optional coaching-run mode when today's plan exists
     - Track GPS route points and timestamps
     - Calculate duration, distance, pace, calories
     - Save record via `POST /api/running/records`
   - iOS implication:
     - Use `Map`/MapKit and `CLLocationManager`.
     - Add `NSLocationWhenInUseUsageDescription`; add background location only after foreground tracking is stable.
     - Implement free-running MVP before coaching-running integration.

4. Records
   - Files:
     - `Neo-Stride/app/src/main/java/com/neostride/app/feature/record/RecordFragment.java`
     - `Neo-Stride/app/src/main/java/com/neostride/app/feature/record/MonthPageFragment.java`
     - `Neo-Stride/app/src/main/java/com/neostride/app/feature/record/RecordDetailFragment.java`
   - API:
     - `GET /api/running/records/user/{user_id}`
     - `GET /api/running/records?year={year}&month={month}`
     - `GET /api/running/records/{record_id}`
   - iOS implication:
     - Build monthly calendar/list and record detail with route polyline.

5. Coaching
   - Files:
     - `Neo-Stride/app/src/main/java/com/neostride/app/feature/coaching/CoachingFragment.java`
     - `Neo-Stride/app/src/main/java/com/neostride/app/feature/coaching/GoalSettingFragment.java`
     - `Neo-Stride/app/src/main/java/com/neostride/app/feature/coaching/GoalStorage.java`
     - `Neo-Stride/app/src/main/java/com/neostride/app/feature/coaching/repository/CoachingRepository.java`
   - API:
     - `POST /api/coaching/goals`
     - `GET /api/coaching/goals/active?user_id={user_id}`
     - `GET /api/coaching/plans/today?user_id={user_id}`
     - `POST /api/coaching/plans/{plan_day_id}/feedback`
     - `DELETE /api/coaching/goals/{goal_id}`
   - Important Android caveat:
     - Android still uses local `GoalStorage` heavily; server sync exists but the UI is not fully server-first.
   - iOS implication:
     - Do not copy the local-first SharedPreferences design blindly.
     - Make iOS server-first: fetch active goal on screen open, cache only for offline display if needed.

6. Lower-priority/static screens
   - Files:
     - `feature/feed/FeedFragment.java`
     - `feature/event/EventFragment.java`
     - `feature/tip/TipFragment.java`
     - `feature/search/SearchFragment.java`
     - `feature/notification/NotificationFragment.java`
   - iOS implication:
     - Stub after core flows unless the capstone demo requires them visually.

---

## 2. iOS Product Scope

### MVP 1: Demo-capable core app

Must have:
- Login
- Signup
- Main tab shell
- Free running tracking screen
- Save running record
- Monthly records screen
- Record detail screen with route
- Coaching goal setup
- Active coaching plan display

Nice-to-have after MVP:
- Today coaching run button integrated into Running tab
- AI feedback after completing a coaching run
- Goal deletion/history
- Notifications screen
- Community/feed/event/tip screens
- Apple Watch companion
- HealthKit sync

Explicit non-goals for first implementation:
- Rewriting backend API
- Migrating Android to Kotlin/Compose
- Fully offline coaching planner
- Background GPS tracking before foreground tracking passes manual QA
- HealthKit before running save and record display work reliably

---

## 3. Recommended iOS Project Structure

Create these groups/files under `/home/yoonhyeon/projects/Neo-Stride/Neo-Stride-ios/Neo-Stride-ios`:

```text
Neo-Stride-ios/
  App/
    NeoStrideApp.swift
    AppConfig.swift
    AppEnvironment.swift
  Core/
    Network/
      APIClient.swift
      APIEndpoint.swift
      APIError.swift
      AuthInterceptor.swift
    Auth/
      AuthStore.swift
      KeychainAuthStore.swift
      SessionState.swift
    Location/
      LocationTracker.swift
      RunningMetricsCalculator.swift
    DesignSystem/
      NeoStrideColors.swift
      NeoStrideButtonStyle.swift
      NeoStrideCard.swift
  Features/
    Auth/
      LoginView.swift
      SignupView.swift
      AuthViewModel.swift
      AuthModels.swift
    Main/
      MainTabView.swift
      ProfileMenuView.swift
    Running/
      RunningView.swift
      RunningViewModel.swift
      RunningModels.swift
      RouteMapView.swift
    Records/
      RecordsView.swift
      RecordDetailView.swift
      RecordsViewModel.swift
      RecordModels.swift
    Coaching/
      CoachingView.swift
      GoalSettingView.swift
      CoachingViewModel.swift
      CoachingModels.swift
    Community/
      CommunityPlaceholderView.swift
    Notification/
      NotificationView.swift
  Resources/
    Assets.xcassets
    PreviewData/
      sample-running-record.json
      sample-active-goal.json
```

Test files:

```text
Neo-Stride-iosTests/
  APIClientTests.swift
  AuthViewModelTests.swift
  RunningMetricsCalculatorTests.swift
  CoachingDTOTests.swift

Neo-Stride-iosUITests/
  AuthFlowUITests.swift
  MainTabUITests.swift
```

---

## 4. API Contract Mapping

The iOS app must implement Codable models matching the JSON names in `frontend-api-spec.md`.

### Auth

- `LoginRequest`
  - `email: String`
  - `password: String`
- `LoginResponse`
  - `status: String`
  - `message: String`
  - `userId: Int`, CodingKey `user_id`
  - `email: String`
  - `name: String`
  - `nickname: String?`
  - `accessToken: String`, CodingKey `access_token`
  - `refreshToken: String`, CodingKey `refresh_token`
- `SignupRequest`
  - `email: String`
  - `name: String`
  - `password: String`
- `SignupResponse`
  - `status`, `message`, `userId`, `email`, `name`

### Running

- `RunningRecordRequest`
  - `userId` -> `user_id`
  - `planId` -> `plan_id`, nullable
  - `totalDistance` -> `total_distance`
  - `duration` seconds
  - `pace` minutes/km
  - `calories`
  - `routeDetail` -> `route_detail`
  - `gpsTraces` -> `gps_traces`
- `GpsTraceRequest`
  - `latitude`
  - `longitude`
  - `time`, format `yyyy-MM-dd HH:mm:ss`
- `RunningRecordResponse`
  - `runRecordId` -> `run_record_id`
  - `createdAt` -> `created_at`
  - `totalDistance`, `duration`, `pace`, `calories`
  - `gpsTraces`
  - `segmentPaces` -> `segment_paces`

### Coaching

- `GoalRequest`
  - `userId` -> `user_id`
  - `periodType` -> `period_type`
  - `customWeeks` -> `custom_weeks`
  - `runningDays` -> `running_days`
  - `goalDistanceKm` -> `goal_distance_km`
  - `goalPaceMinPerKm` -> `goal_pace_min_per_km`
  - `startDate` -> `start_date`
- `GoalResponse`
  - `goalId` -> `goal_id`
  - `hasActiveGoal` -> `has_active_goal`
  - `status`
  - `goal`
  - `planDays` -> `plan_days`
- `PlanDayResponse`
  - `planDayId` -> `plan_day_id`
  - `planDate` -> `plan_date`
  - `dayDistanceKm` -> `day_distance_km`
  - `dayPaceMinPerKm` -> `day_pace_min_per_km`
  - `description`
  - `isCompleted` -> `is_completed`
  - `aiFeedbackComment` -> `ai_feedback_comment`
  - `aiFeedbackAt` -> `ai_feedback_at`

---

## 5. Implementation Phases

### Phase 0: Baseline setup and guardrails

Objective: Make the Xcode project ready for real development without changing product behavior.

Tasks:
1. Rename template files if needed.
   - Modify: `Neo-Stride-ios/Neo-Stride-ios/Neo_Stride_iosApp.swift`
   - Modify: `Neo-Stride-ios/Neo-Stride-ios/ContentView.swift`
   - Expected: App launches to a placeholder `RootView`.
2. Add app config.
   - Create: `Neo-Stride-ios/Neo-Stride-ios/App/AppConfig.swift`
   - Define `baseURL` using Info.plist or build setting.
   - Default dev URL should be easy to override; do not hardcode secrets.
3. Add design tokens.
   - Create: `Core/DesignSystem/NeoStrideColors.swift`
   - Include black/dark surface, white text, neon accent `#CCFF00`, warning orange.
4. Add test target sanity checks.
   - Modify: `Neo-Stride-iosTests/Neo_Stride_iosTests.swift`
   - Add a simple config test.
5. Verify.
   - Run in Xcode: build iOS app target.
   - Run tests: Product > Test.
   - Commit: `chore: prepare iOS app foundation`.

### Phase 1: Networking and auth foundation

Objective: Establish shared networking and session state before feature UI.

Tasks:
1. Create `APIError`.
   - Create: `Core/Network/APIError.swift`
   - Include invalidURL, unauthorized, serverError(status:body:), decoding, network.
2. Create `APIClient`.
   - Create: `Core/Network/APIClient.swift`
   - Use `URLSession` and async/await.
   - Add JSON encoder/decoder with explicit CodingKeys in models, not global snake_case conversion, because API field names are mixed and should remain audit-friendly.
3. Create `AuthStore` protocol and Keychain implementation.
   - Create: `Core/Auth/AuthStore.swift`
   - Create: `Core/Auth/KeychainAuthStore.swift`
   - Store access token, refresh token, user id, nickname/name.
4. Create Auth DTOs.
   - Create: `Features/Auth/AuthModels.swift`
   - Add unit tests that decode sample login/signup JSON from the API spec.
5. Create `AuthViewModel`.
   - Create: `Features/Auth/AuthViewModel.swift`
   - Methods: `login(email:password:keepLogin:)`, `signup(email:name:password:)`, `logout()`.
6. Build Login/Signup UI.
   - Create: `Features/Auth/LoginView.swift`
   - Create: `Features/Auth/SignupView.swift`
   - Match Android validation messages: email required, password required, server connection failure.
7. Verify.
   - Unit tests pass for DTO decoding and store behavior.
   - Manual: login succeeds against configured backend; token/user id saved.
   - Commit: `feat: add iOS authentication foundation`.

### Phase 2: Main navigation shell

Objective: Match Android `MainActivity` navigation in SwiftUI.

Tasks:
1. Create root session gate.
   - Create: `App/SessionState.swift` or `Core/Auth/SessionState.swift`
   - App shows Login if not authenticated, MainTabView if authenticated.
2. Create main tab UI.
   - Create: `Features/Main/MainTabView.swift`
   - Tabs: Running, Record, Coaching, Community.
3. Add toolbar actions.
   - Create: `Features/Main/ProfileMenuView.swift`
   - Create: `Features/Notification/NotificationView.swift`
   - Logout clears Keychain and returns to Login.
4. Add placeholder screens for incomplete tabs.
   - Create: `Features/Community/CommunityPlaceholderView.swift`
5. Verify.
   - UI test launches app and confirms login screen when logged out.
   - Manual: logout returns to login.
   - Commit: `feat: add iOS main navigation shell`.

### Phase 3: Running MVP

Objective: Implement free running tracking and save records to backend.

Tasks:
1. Add location permissions.
   - Modify: Xcode project Info.plist settings.
   - Add `NSLocationWhenInUseUsageDescription` with Korean user-facing text.
   - Do not add background location yet.
2. Create `LocationTracker`.
   - Create: `Core/Location/LocationTracker.swift`
   - Wrap `CLLocationManager`, authorization state, latest location, route points.
3. Create `RunningMetricsCalculator`.
   - Create: `Core/Location/RunningMetricsCalculator.swift`
   - Match Android behavior where practical:
     - minimum movement filter: 5m
     - accuracy filter: 20m
     - max speed filter: 12m/s
     - duration in seconds
     - distance in km
     - pace in min/km
4. Add metric unit tests.
   - Create: `Neo-Stride-iosTests/RunningMetricsCalculatorTests.swift`
   - Test distance accumulation, pause exclusion, zero-distance pace safety.
5. Create running DTOs and API calls.
   - Create: `Features/Running/RunningModels.swift`
   - Add `saveRunningRecord` endpoint to `APIClient` or `RunningService`.
6. Build Running UI.
   - Create: `Features/Running/RunningView.swift`
   - Create: `Features/Running/RouteMapView.swift`
   - States: ready, running, paused, result.
   - Buttons: start, pause/resume, stop, confirm/save.
7. Verify.
   - Manual: location permission prompt appears.
   - Manual: route line appears on simulator/device if location is available.
   - Manual: confirm posts to `POST /api/running/records`.
   - Commit: `feat: add free running tracking on iOS`.

### Phase 4: Records

Objective: Show saved runs and details.

Tasks:
1. Create record DTOs.
   - Create/extend: `Features/Records/RecordModels.swift`
2. Add records API service.
   - Endpoints:
     - `GET /api/running/records/user/{user_id}`
     - `GET /api/running/records?year=&month=`
     - `GET /api/running/records/{record_id}`
3. Build monthly records screen.
   - Create: `Features/Records/RecordsView.swift`
   - MVP: month selector + list of runs; calendar grid can follow.
4. Build detail screen.
   - Create: `Features/Records/RecordDetailView.swift`
   - Show distance, duration, pace, calories, created_at, route polyline.
5. Verify.
   - Unit: decode record list sample.
   - Manual: saved run appears in list and detail opens.
   - Commit: `feat: add running records on iOS`.

### Phase 5: Coaching server-first MVP

Objective: Implement coaching based on backend API, avoiding Android's local-only storage trap.

Tasks:
1. Create coaching DTOs.
   - Create: `Features/Coaching/CoachingModels.swift`
   - Unit test decoding of `GoalResponse`, `TodayPlanResponse`, `FeedbackResponse`.
2. Add coaching API service.
   - Endpoints:
     - `POST /api/coaching/goals`
     - `GET /api/coaching/goals/active?user_id=`
     - `GET /api/coaching/plans/today?user_id=`
     - `POST /api/coaching/plans/{plan_day_id}/feedback`
     - `DELETE /api/coaching/goals/{goal_id}`
3. Build coaching dashboard.
   - Create: `Features/Coaching/CoachingView.swift`
   - Show active goal, weekly/day plan list, empty state, delete goal.
4. Build goal setup.
   - Create: `Features/Coaching/GoalSettingView.swift`
   - Match Android choices:
     - period: 1 month, 3 months, 6 months, 1 year, custom weeks
     - running days: sun-mon-tue-wed-thu-fri-sat
     - distance: 3, 5, 10, 20, 40km, custom
     - pace: slider/custom min/sec
   - Send `GoalRequest` to backend on confirm.
5. Integrate today's plan into Running tab.
   - Running tab queries `GET /api/coaching/plans/today`.
   - If today plan exists, show coaching start option.
6. Add feedback after coaching run.
   - After saving a coaching run, call `POST /api/coaching/plans/{plan_day_id}/feedback` with actual metrics.
7. Verify.
   - Manual: create goal, app reloads active plan from server.
   - Manual: delete goal updates server and UI.
   - Manual: today plan appears in Running tab.
   - Commit: `feat: add server-backed coaching on iOS`.

### Phase 6: Polish, QA, and release prep

Objective: Prepare for capstone demo/test distribution.

Tasks:
1. Replace placeholder community/notification screens if needed.
2. Add empty/error/loading states to every network screen.
3. Add Korean copy pass.
4. Add app icons and launch screen.
5. Add privacy strings.
   - Location usage
   - Network usage note if needed
   - HealthKit only if implemented
6. Add CI later if macOS runner is available.
7. Manual QA checklist:
   - Signup
   - Login
   - Keep login after app restart
   - Logout
   - Free run start/pause/stop/save
   - Record list/detail
   - Goal creation
   - Active plan reload
   - Today plan running
   - Feedback
8. Commit: `chore: polish iOS app for demo`.

---

## 6. Key Risks and Decisions

1. Backend base URL
   - Android currently defaults to a Postman mock URL via `BuildConfig.BASE_URL`.
   - iOS should use an environment-based base URL and avoid hardcoding the mock URL for production.

2. Token storage mismatch in Android
   - Android `LoginActivity` writes `SharedPreferences("auth")`, while `TokenManager` reads `neo_stride_auth`.
   - iOS must not replicate this split.
   - Store tokens and user id through one `AuthStore` only.

3. Android local coaching state
   - Android has server APIs but still relies heavily on `GoalStorage` local SharedPreferences.
   - iOS should be server-first to make Android/iOS behavior consistent through the backend.

4. Map provider
   - Android uses Google Maps.
   - iOS default should be MapKit to avoid an extra Google Maps iOS dependency and API key setup.
   - If visual parity with Android Google Maps is required, decide before Phase 3.

5. Background running
   - Android declares foreground service permissions.
   - iOS background location requires stricter UX, App Store privacy justification, and settings.
   - Defer background mode until foreground running flow is stable.

6. Apple Watch target
   - The Xcode project currently includes a watchOS target.
   - Treat watchOS as future work unless explicitly needed for demo.

---

## 7. First Execution Recommendation

Start with Phase 0 and Phase 1 only.

Reason:
- Auth/session/network foundations decide the shape of every later feature.
- Running, records, and coaching all need reliable user_id and Authorization handling.
- This catches backend URL and token issues early before building many screens.

Suggested first commit sequence:
1. `chore: prepare iOS app foundation`
2. `feat: add iOS API client`
3. `feat: add iOS auth models and session store`
4. `feat: add login and signup screens`
5. `feat: add main tab shell`

Stop after Phase 1/2 and manually verify against backend before implementing running tracking.
