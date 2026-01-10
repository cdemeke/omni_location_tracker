# Product Requirements Document: OmniSite Tracker

## Overview

OmniSite Tracker is an iOS application that helps insulin pump users track and rotate their infusion site placements. The app provides visual body mapping, placement history, and smart recommendations to promote healthy site rotation habits.

## Problem Statement

People with Type 1 Diabetes who use insulin pumps must rotate their infusion sites every 2-3 days. Poor rotation leads to:

- **Lipohypertrophy** — fatty lumps that impair insulin absorption
- **Inconsistent glucose control** — from variable absorption rates
- **Tissue damage** — scarring that reduces usable placement areas

Current tracking methods (memory, paper logs, calendar apps) are unreliable and lack visual context. Caregivers managing a child's diabetes face additional challenges remembering which sites were used.

## Goals

1. Reduce site reuse within recommended rest periods
2. Provide clear visual tracking of all placement zones
3. Simplify logging to under 10 seconds per placement
4. Deliver smart recommendations based on rotation history

## Target Users

| User Type | Description |
|-----------|-------------|
| **Primary** | Adults with T1D using tubeless pumps (Omnipod) |
| **Secondary** | Parents/caregivers of children with T1D |
| **Tertiary** | Users of tubed insulin pumps (Tandem, Medtronic) |

## User Stories

### Logging a Placement
> As a pump user, I want to quickly log where I placed my new pod so I can track my rotation history.

### Viewing Recommendations
> As a pump user, I want to see which site I should use next based on how long each area has rested.

### Reviewing History
> As a caregiver, I want to see when and where previous placements occurred so I can ensure proper rotation.

### Editing a Mistake
> As a user, I want to edit or delete an incorrect log entry so my history stays accurate.

## Features

### v1.0 (MVP)

| Feature | Description | Priority |
|---------|-------------|----------|
| Body Diagram | Interactive front/back view with tappable zones | P0 |
| Placement Logging | Confirm site selection with optional notes | P0 |
| Site Recommendations | Algorithm suggests optimal next site | P0 |
| Placement History | Chronological list grouped by day | P0 |
| Edit/Delete Entries | Modify or remove logged placements | P1 |
| Site Status Colors | Visual indicators (available, recent, rested) | P1 |
| Filter History | View history by specific body location | P2 |

### v1.1 (Future)

| Feature | Description |
|---------|-------------|
| Push Notifications | Remind user when pod change is due |
| iCloud Sync | Share data across user's devices |
| Data Export | Export history to CSV/PDF |
| Apple Watch | Quick logging from wrist |
| HealthKit | Write site changes to Apple Health |
| Widgets | Home screen glance at last placement |

## Functional Requirements

### Body Diagram
- Display front view with: Left Abdomen, Right Abdomen, Left Thigh, Right Thigh
- Display back view with: Left Arm, Right Arm, Lower Back
- Toggle between front/back views
- Zone buttons positioned in corners with dotted lines to body locations
- Color-code zones based on status

### Placement Logging
- Tap zone to initiate logging flow
- Show confirmation sheet with location name
- Allow optional note entry (max 200 characters)
- Display warning if site used within 7 days
- Save with current timestamp
- Show success feedback on completion

### Recommendations
- Calculate days since last use for each zone
- Prioritize zones unused for 7+ days
- Avoid recommending sites used within 3 days
- Display recommendation prominently on home screen

### History
- List all placements newest-first
- Group by calendar day
- Show location, relative time, and notes
- Support tap to edit, swipe to delete
- Filter by specific body location

## Non-Functional Requirements

| Requirement | Specification |
|-------------|---------------|
| Platform | iOS 17.0+ |
| Storage | Local device (SwiftData) |
| Performance | App launch < 2 seconds |
| Offline | Fully functional without network |
| Accessibility | VoiceOver compatible |
| Localization | English (v1.0) |

## Technical Architecture

```
┌─────────────────────────────────────────┐
│                 Views                    │
│  HomeView · HistoryView · ContentView   │
├─────────────────────────────────────────┤
│              ViewModel                   │
│          PlacementViewModel              │
├─────────────────────────────────────────┤
│               Models                     │
│     PlacementLog · BodyLocation          │
├─────────────────────────────────────────┤
│             SwiftData                    │
│         Local Persistence                │
└─────────────────────────────────────────┘
```

## Success Metrics

| Metric | Target |
|--------|--------|
| Daily Active Users | Track for growth |
| Placements Logged per User | ≥ 2 per week |
| App Store Rating | ≥ 4.5 stars |
| Crash-Free Sessions | ≥ 99.5% |
| Site Reuse Violations | Decrease over time per user |

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| App Review rejection | Delays launch | Include medical disclaimer, follow Health app guidelines |
| Low adoption | Wasted effort | Beta test with T1D community first |
| Data loss | User frustration | Implement iCloud backup in v1.1 |
| Inaccurate recommendations | Reduced trust | Allow manual override, show reasoning |

## Out of Scope (v1.0)

- Blood glucose tracking
- Insulin dosing calculations
- Integration with pump hardware
- Multi-user/family accounts
- Android version

## Appendix

### Site Rest Period Research

Medical guidance suggests rotating insulin pump sites every 2-3 days and allowing 7+ days before reusing the same area. This app uses:
- **Recent** (orange): Used within 7 days
- **Rested** (green): 7+ days since last use
- **Available** (gray): Never used or fully rested

### Competitor Analysis

| App | Pros | Cons |
|-----|------|------|
| Glooko | Comprehensive diabetes management | Complex, no visual body map |
| mySugr | Popular, gamified | Focused on BG, not site rotation |
| Diabetes:M | Feature-rich | Overwhelming UI, Android-first |

OmniSite Tracker differentiates by focusing solely on site rotation with a visual-first approach.
