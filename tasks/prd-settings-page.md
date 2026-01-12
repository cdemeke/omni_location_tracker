# PRD: Settings Page

## Introduction

Add a dedicated Settings page to OmniSite Tracker where users can customize their site rotation preferences. Users will be able to adjust the rest duration between site uses, enable/disable default body locations, add custom site locations, and configure notification preferences. This gives users flexibility to tailor the app to their specific pump therapy needs and personal preferences.

## Goals

- Allow users to customize the minimum rest duration for site rotation (default 3 days)
- Enable users to toggle on/off the 8 default body locations
- Allow users to add custom-named site locations beyond the defaults
- Provide notification preferences for rotation reminders
- Add Settings as a 4th tab in the bottom navigation
- Store all settings locally on device using SwiftData

## User Stories

### US-001: Create UserSettings Model
**Description:** As a developer, I need a data model to persist user settings so preferences are saved between app sessions.

**Acceptance Criteria:**
- [ ] Create `UserSettings` SwiftData model with fields: `minimumRestDays` (Int, default 3), `showDisabledSitesInHistory` (Bool, default true), `createdAt` (Date), `updatedAt` (Date)
- [ ] Model should be a singleton pattern (only one settings record per app)
- [ ] Add model to SwiftData container in app entry point
- [ ] Typecheck passes

### US-002: Create CustomSite Model
**Description:** As a developer, I need a data model to store user-defined custom site locations.

**Acceptance Criteria:**
- [ ] Create `CustomSite` SwiftData model with fields: `id` (UUID), `name` (String), `iconName` (String, default "star.fill"), `isEnabled` (Bool, default true), `createdAt` (Date)
- [ ] Name must be unique and non-empty
- [ ] iconName stores SF Symbol name from curated list
- [ ] Add model to SwiftData container in app entry point
- [ ] Typecheck passes

### US-003: Create DisabledDefaultSite Model
**Description:** As a developer, I need to track which default body locations the user has disabled.

**Acceptance Criteria:**
- [ ] Create `DisabledDefaultSite` SwiftData model with fields: `id` (UUID), `location` (BodyLocation raw value as String), `disabledAt` (Date)
- [ ] Stores only disabled locations (enabled by default if no record exists)
- [ ] Add model to SwiftData container in app entry point
- [ ] Typecheck passes

### US-004: Create NotificationSettings Model
**Description:** As a developer, I need a data model to persist notification preferences.

**Acceptance Criteria:**
- [ ] Create `NotificationSettings` SwiftData model with fields: `notificationsEnabled` (Bool, default false), `reminderHour` (Int, default 9), `reminderMinute` (Int, default 0), `daysBeforeReminder` (Int, default 0)
- [ ] Model should be a singleton pattern (only one notification settings record)
- [ ] Add model to SwiftData container in app entry point
- [ ] Typecheck passes

### US-005: Create SettingsView Basic Structure
**Description:** As a user, I want a Settings tab so I can access app preferences.

**Acceptance Criteria:**
- [ ] Create `SettingsView.swift` in Views folder
- [ ] Add Settings tab to ContentView as 4th tab
- [ ] Use SF Symbol "gearshape.fill" for tab icon
- [ ] Use NavigationStack with "Settings" title
- [ ] Use WarmGradientBackground for consistency
- [ ] Tab styling matches existing Home/History/Patterns tabs
- [ ] Typecheck passes

### US-006: Create SettingsViewModel
**Description:** As a developer, I need a view model to manage settings state and persistence.

**Acceptance Criteria:**
- [ ] Create `SettingsViewModel.swift` in ViewModels folder
- [ ] Add method to get/create singleton UserSettings
- [ ] Add method to get/create singleton NotificationSettings
- [ ] Add methods: `updateRestDuration(days: Int)`, `getRestDuration() -> Int`
- [ ] Add methods: `getDisabledDefaultSites() -> [BodyLocation]`, `toggleDefaultSite(location: BodyLocation)`
- [ ] Add methods: `getCustomSites() -> [CustomSite]`, `addCustomSite(name: String)`, `deleteCustomSite(id: UUID)`, `toggleCustomSite(id: UUID)`
- [ ] Typecheck passes

### US-007: Implement Rest Duration Setting UI
**Description:** As a user, I want to customize how many days a site should rest before being recommended again.

**Acceptance Criteria:**
- [ ] Add "Rotation Settings" section in SettingsView
- [ ] Display current rest duration with label "Minimum Rest Days"
- [ ] Use Stepper or TextField for numeric input
- [ ] Allow any positive integer (minimum 1 day)
- [ ] Default value is 3 days
- [ ] Changes save automatically
- [ ] Show helper text explaining what this setting does
- [ ] Typecheck passes

### US-008: Implement Default Sites Toggle UI
**Description:** As a user, I want to enable or disable default body locations so I only see sites I actually use.

**Acceptance Criteria:**
- [ ] Add "Body Sites" section in SettingsView
- [ ] List all 8 default BodyLocation values with toggle switches
- [ ] Display location icon and display name for each
- [ ] Enabled sites show toggle ON, disabled show toggle OFF
- [ ] At least one site must remain enabled (show alert if user tries to disable all)
- [ ] Changes save automatically when toggled
- [ ] Typecheck passes

### US-009: Implement Custom Sites Management UI
**Description:** As a user, I want to add my own custom site locations beyond the defaults.

**Acceptance Criteria:**
- [ ] Add "Custom Sites" subsection below default sites
- [ ] Show list of user-created custom sites with icon, name, toggle, and delete button
- [ ] Add "Add Custom Site" button that shows sheet with name input and icon picker
- [ ] Icon picker displays curated grid of 12-15 SF Symbols (see Design Considerations)
- [ ] Validate custom site name is not empty and not duplicate
- [ ] Show error message for invalid input
- [ ] Swipe-to-delete or delete button for removing custom sites
- [ ] No limit on number of custom sites
- [ ] Changes save automatically
- [ ] Typecheck passes

### US-010: Implement Notification Settings UI
**Description:** As a user, I want to configure reminder notifications for site rotation.

**Acceptance Criteria:**
- [ ] Add "Notifications" section in SettingsView
- [ ] Master toggle for "Enable Reminders"
- [ ] When enabled, show time picker for reminder time (default 9:00 AM)
- [ ] Option for "Remind me X days before site is ready" (0 = day site is ready)
- [ ] Request notification permission when user enables reminders
- [ ] Show system settings link if permissions denied
- [ ] Disabled state hides time picker options
- [ ] Use default iOS notification sound (not customizable)
- [ ] Typecheck passes

### US-011: Implement History Display Preference
**Description:** As a user, I want to choose whether disabled sites appear in my history and patterns views.

**Acceptance Criteria:**
- [ ] Add "Data Display" section in SettingsView
- [ ] Toggle for "Show Disabled Sites in History" (default: ON)
- [ ] When ON, history and patterns include all sites (even disabled ones)
- [ ] When OFF, history and patterns filter out disabled sites
- [ ] Helper text explains the setting behavior
- [ ] Changes apply immediately to History and Patterns views
- [ ] Typecheck passes

### US-012: Integrate History Display Preference
**Description:** As a developer, I need to filter history and patterns based on the user's display preference.

**Acceptance Criteria:**
- [ ] Update HistoryView to check `showDisabledSitesInHistory` setting
- [ ] Update PatternsView heatmap data to respect the setting
- [ ] Update zone statistics to respect the setting
- [ ] When OFF, placements at disabled sites are excluded from views
- [ ] Typecheck passes

### US-013: Integrate Rest Duration with Recommendation Logic
**Description:** As a user, I want the app's recommendations to respect my custom rest duration setting.

**Acceptance Criteria:**
- [ ] Update `PlacementViewModel.minimumRestDays` to read from UserSettings
- [ ] Recommendation algorithm uses user's custom rest duration instead of hardcoded 3 days
- [ ] Status colors on body diagram reflect user's custom rest duration
- [ ] Rotation score calculation uses user's custom rest duration
- [ ] Typecheck passes

### US-014: Integrate Site Toggles with Body Diagram
**Description:** As a user, I want the body diagram to only show sites I have enabled.

**Acceptance Criteria:**
- [ ] Update `BodyDiagramView` to filter out disabled default locations
- [ ] Update `HeatmapBodyDiagramView` to filter out disabled default locations
- [ ] Disabled sites do not appear on body diagram
- [ ] Disabled sites do not appear in recommendations
- [ ] Disabled sites do not appear in zone statistics
- [ ] Typecheck passes

### US-015: Integrate Custom Sites with App
**Description:** As a user, I want my custom sites to appear alongside default sites throughout the app.

**Acceptance Criteria:**
- [ ] Custom sites appear in a separate "Custom" section on Home screen (not on body diagram)
- [ ] Custom sites can be selected for placement logging
- [ ] Custom sites appear in History view entries
- [ ] Custom sites appear in Patterns zone statistics
- [ ] Custom sites included in heatmap data calculations
- [ ] Custom site icon (from curated list) displayed alongside name
- [ ] Typecheck passes

### US-016: Implement Notification Scheduling
**Description:** As a user, I want to receive notifications when sites are ready to use again.

**Acceptance Criteria:**
- [ ] Schedule local notifications based on user's notification settings
- [ ] Notification triggers at user's preferred time on the day site becomes ready
- [ ] Notification content shows which site(s) are now available
- [ ] Notifications update when new placements are logged
- [ ] Notifications cancelled when reminders are disabled
- [ ] Use default iOS notification sound
- [ ] Typecheck passes

### US-017: Add Reset to Defaults Option
**Description:** As a user, I want to reset my settings to defaults if needed.

**Acceptance Criteria:**
- [ ] Add "Reset to Defaults" button at bottom of Settings page
- [ ] Show confirmation alert before resetting
- [ ] Reset restores: rest days to 3, all default sites enabled, custom sites deleted, notifications disabled, show disabled sites ON
- [ ] Show success feedback after reset
- [ ] Typecheck passes

### US-018: Add About Section
**Description:** As a user, I want to see app version and attribution information.

**Acceptance Criteria:**
- [ ] Add "About" section at bottom of Settings page
- [ ] Display app version number
- [ ] Display "Made with love" attribution text
- [ ] Link to privacy policy (opens in Safari)
- [ ] Link to support/feedback (opens email or web)
- [ ] Typecheck passes

## Functional Requirements

- FR-1: Settings must persist locally using SwiftData
- FR-2: Minimum rest days must accept any positive integer (1 or greater)
- FR-3: Default rest duration is 3 days
- FR-4: All 8 default body locations are enabled by default
- FR-5: At least one site (default or custom) must remain enabled at all times
- FR-6: Custom site names must be unique and non-empty
- FR-7: Custom sites can be toggled on/off independently
- FR-8: Notification permissions must be requested before scheduling
- FR-9: Settings changes must take effect immediately throughout the app
- FR-10: Body diagram must only display enabled default sites
- FR-11: Recommendations must only suggest enabled sites
- FR-12: Reset to defaults must require user confirmation

## Non-Goals (Out of Scope)

- iCloud sync of settings across devices
- Per-site custom rest durations (all sites use same duration)
- Custom icons for custom sites on body diagram
- Push notifications (local notifications only)
- Scheduled placement reminders (only "site ready" notifications)
- Export/import of settings
- Multiple user profiles

## Design Considerations

### Settings Page Layout
```
┌─────────────────────────────────┐
│ Settings                        │
├─────────────────────────────────┤
│ ROTATION SETTINGS               │
│ ┌─────────────────────────────┐ │
│ │ Minimum Rest Days    [3] ▲▼│ │
│ │ Days before a site can be  │ │
│ │ used again                  │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ BODY SITES                      │
│ ┌─────────────────────────────┐ │
│ │ 💪 Left Arm          [ON]  │ │
│ │ 💪 Right Arm         [ON]  │ │
│ │ ... (all 8 locations)      │ │
│ └─────────────────────────────┘ │
│                                 │
│ CUSTOM SITES                    │
│ ┌─────────────────────────────┐ │
│ │ ⭐ Upper Buttock    [ON] 🗑│ │
│ │ + Add Custom Site          │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ DATA DISPLAY                    │
│ ┌─────────────────────────────┐ │
│ │ Show Disabled Sites   [ON] │ │
│ │ in History & Patterns      │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ NOTIFICATIONS                   │
│ ┌─────────────────────────────┐ │
│ │ Enable Reminders     [OFF] │ │
│ │ Reminder Time    9:00 AM   │ │
│ │ Days Before         [0]    │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ ABOUT                           │
│ Version 1.0.0                   │
│ Privacy Policy                  │
│ Send Feedback                   │
├─────────────────────────────────┤
│ [    Reset to Defaults    ]     │
└─────────────────────────────────┘
```

### Curated Icon List for Custom Sites
Users can choose from these 15 SF Symbols when creating a custom site:
```
star.fill          - Default/general
circle.fill        - Generic dot
square.fill        - Generic square
triangle.fill      - Triangle marker
heart.fill         - Heart
bolt.fill          - Lightning bolt
leaf.fill          - Leaf/natural
drop.fill          - Drop/liquid
flame.fill         - Flame
moon.fill          - Moon
sun.max.fill       - Sun
cross.fill         - Medical cross
pills.fill         - Pills/medication
bandage.fill       - Bandage
syringe.fill       - Syringe
```

### Reusable Components
- Use existing `SectionHeader` for section titles
- Use existing card styles (`.neumorphicCard()`) for sections
- Use standard SwiftUI `Toggle` for on/off switches
- Use `Stepper` or custom number input for rest days

## Technical Considerations

- SwiftData models need to be added to the model container in `OmniSiteTrackerApp.swift`
- `PlacementViewModel.minimumRestDays` is currently hardcoded - needs to become dynamic
- `BodyLocation` enum may need extension to support custom sites (or use separate data type)
- Custom sites should use a different identifier system than `BodyLocation` enum
- Notification scheduling requires `UNUserNotificationCenter` and permission handling
- Consider using `@AppStorage` for simple boolean flags vs SwiftData for complex data

## Success Metrics

- Users can customize rest duration in under 3 taps
- Users can disable a site in under 2 taps
- Users can add a custom site in under 4 taps
- Settings changes reflect immediately in Home/Patterns views
- No data loss when updating settings

## Design Decisions (Resolved)

1. **Custom site icons:** Users can pick from a curated list of 15 SF Symbols (see Design Considerations)
2. **Custom site limit:** No limit - users can add as many custom sites as they want
3. **Disabled sites in history:** User preference toggle (default ON - show all historical data)
4. **Notification sound:** Use default iOS notification sound (not customizable)

## Open Questions

None - all design decisions have been finalized.
