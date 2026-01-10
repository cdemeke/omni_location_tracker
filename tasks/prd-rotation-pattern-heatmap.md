# PRD: Rotation Pattern View (Heatmap)

## Introduction

Add a dedicated Rotation Pattern View that displays a heatmap overlay on the body diagram showing injection site usage density over customizable time periods. This feature helps users identify overused sites to prevent tissue damage, provides visual feedback on rotation compliance, and enables pattern tracking for sharing with healthcare providers. The heatmap uses the existing status color scheme (gray → orange → red) for visual consistency.

## Goals

- Visualize site usage density across all body locations with a heatmap overlay
- Provide custom date range selection for flexible pattern analysis
- Help users identify overused sites that may lead to lipohypertrophy or scar tissue
- Display detailed usage statistics and trend charts per location
- Enable users to track and share rotation patterns with healthcare providers
- Maintain visual consistency with existing app design (earthy glassmorphism, status colors)

## User Stories

### US-001: Add Rotation Pattern Tab to Navigation
**Description:** As a user, I want a dedicated tab for viewing my rotation patterns so I can easily access usage analytics.

**Acceptance Criteria:**
- [ ] New "Patterns" tab added to main tab navigation (third tab after Home and History)
- [ ] Tab uses appropriate SF Symbol icon (e.g., `chart.bar.doc.horizontal` or `map`)
- [ ] Tab maintains consistent styling with existing Home/History tabs
- [ ] Typecheck/build passes

### US-002: Create Heatmap Body Diagram Component
**Description:** As a user, I want to see a body diagram with color-coded zones showing usage density so I can quickly identify overused areas.

**Acceptance Criteria:**
- [ ] Body diagram displays with heatmap overlay on all 8 zones
- [ ] Zone colors use existing status palette: gray (low/no usage) → orange (moderate) → red (high usage)
- [ ] Color intensity scales based on usage frequency within selected date range
- [ ] Front/back view toggle works identically to existing body diagram
- [ ] Heatmap legend shows color scale with usage frequency labels
- [ ] Typecheck/build passes

### US-003: Implement Custom Date Range Picker
**Description:** As a user, I want to select a custom date range so I can analyze my rotation patterns for any time period.

**Acceptance Criteria:**
- [ ] Date range picker with start and end date selection
- [ ] Quick preset buttons: "Last 7 days", "Last 30 days", "Last 90 days", "All time"
- [ ] Selected range displays clearly above the heatmap
- [ ] Heatmap and all statistics update when date range changes
- [ ] Date picker uses native iOS date picker components
- [ ] Cannot select future dates or end date before start date
- [ ] Typecheck/build passes

### US-004: Calculate and Store Heatmap Data
**Description:** As a developer, I need to compute usage density per location from placement history so the heatmap can display accurate data.

**Acceptance Criteria:**
- [ ] New `HeatmapData` model struct containing location, usage count, and intensity (0-1)
- [ ] ViewModel method `generateHeatmapData(from: Date, to: Date)` returns array of HeatmapData
- [ ] Intensity calculated as ratio: location count / max count across all locations
- [ ] Empty/unused locations return intensity of 0
- [ ] Data recalculates when date range or placements change
- [ ] Typecheck/build passes

### US-005: Display Usage Count Per Zone
**Description:** As a user, I want to see the exact usage count for each zone so I understand the numbers behind the heatmap colors.

**Acceptance Criteria:**
- [ ] Tapping a zone on the heatmap shows usage count in a popover or detail card
- [ ] Detail card shows: zone name, usage count, last used date, percentage of total placements
- [ ] Detail card uses neumorphic card styling consistent with app design
- [ ] Typecheck/build passes

### US-006: Create Zone Usage Statistics List
**Description:** As a user, I want to see a ranked list of all zones by usage so I can understand my rotation habits at a glance.

**Acceptance Criteria:**
- [ ] Scrollable list below heatmap showing all 8 zones
- [ ] Each row displays: zone icon, zone name, usage count, usage bar indicator
- [ ] List sorted by usage count (highest first)
- [ ] Usage bar visually represents relative usage (percentage of max)
- [ ] Rows use existing status colors matching heatmap
- [ ] Typecheck/build passes

### US-007: Add Usage Trend Chart
**Description:** As a user, I want to see a chart showing my usage patterns over time so I can track how my rotation habits change.

**Acceptance Criteria:**
- [ ] Line or bar chart showing placements over time within selected date range
- [ ] Chart grouped by day (for ranges < 30 days) or week (for ranges >= 30 days)
- [ ] Chart uses Swift Charts framework for native iOS look
- [ ] X-axis shows dates, Y-axis shows placement count
- [ ] Chart colors match app's earthy design palette
- [ ] Typecheck/build passes

### US-008: Add Per-Location Trend Breakdown
**Description:** As a user, I want to see usage trends broken down by location so I can identify if I'm favoring certain sites over time.

**Acceptance Criteria:**
- [ ] Stacked bar chart or multi-line chart showing usage by location over time
- [ ] Each location has a distinct color from the app palette
- [ ] Legend identifies each location
- [ ] Tapping a chart segment/line highlights that location
- [ ] Typecheck/build passes

### US-009: Calculate Rotation Compliance Score
**Description:** As a user, I want to see a rotation compliance score so I can understand how well I'm rotating sites.

**Acceptance Criteria:**
- [ ] Compliance score calculated as percentage (0-100%)
- [ ] Score factors in: distribution evenness, rest days between same-site uses
- [ ] Score displayed prominently at top of Patterns view
- [ ] Visual indicator (circular progress, gauge, or similar) shows score
- [ ] Brief explanation text explains what the score means
- [ ] Typecheck/build passes

### US-010: Add Export/Share Functionality
**Description:** As a user, I want to export my rotation pattern data so I can share it with my healthcare provider.

**Acceptance Criteria:**
- [ ] Share button in navigation bar or prominent location
- [ ] Export generates a summary image (screenshot of heatmap + stats)
- [ ] Export also offers PDF option with detailed statistics
- [ ] Uses iOS native share sheet for sharing options
- [ ] Exported content includes date range and generation timestamp
- [ ] Typecheck/build passes

### US-011: Handle Empty State
**Description:** As a user, I want to see helpful guidance when I don't have enough data for a meaningful heatmap.

**Acceptance Criteria:**
- [ ] Empty state shown when no placements exist in selected date range
- [ ] Friendly message explains what the view will show once data exists
- [ ] Suggests logging placements to see patterns
- [ ] Maintains visual consistency with app design
- [ ] Typecheck/build passes

## Functional Requirements

- FR-1: Add "Patterns" tab as third item in main tab navigation with appropriate icon
- FR-2: Display body diagram with color-coded heatmap overlay using existing status colors (gray → orange → red)
- FR-3: Support front/back body view toggle on heatmap diagram
- FR-4: Provide custom date range picker with start/end date selection
- FR-5: Include quick date range presets (7 days, 30 days, 90 days, all time)
- FR-6: Calculate usage density per location as ratio of location count to maximum count
- FR-7: Display interactive heatmap legend showing color-to-frequency mapping
- FR-8: Show zone detail popover on tap with usage count, last used date, and percentage
- FR-9: Display ranked list of all zones sorted by usage count
- FR-10: Render time-series chart showing placements over time (daily or weekly grouping)
- FR-11: Render per-location breakdown chart showing distribution trends
- FR-12: Calculate and display rotation compliance score (0-100%)
- FR-13: Provide export functionality generating shareable image and PDF
- FR-14: Show empty state with guidance when no data exists for selected range
- FR-15: Persist selected date range preference across app sessions

## Non-Goals (Out of Scope)

- Cloud sync or backup of pattern data (local only, consistent with existing app)
- Healthcare provider portal or direct integration with medical systems
- Push notifications or reminders based on heatmap patterns
- Machine learning predictions for future site recommendations
- Comparison with other users or anonymized population data
- Apple Health or HealthKit integration
- Automated PDF emailing to healthcare providers
- Real-time heatmap updates during placement (update on view load is sufficient)

## Design Considerations

### UI/UX Requirements
- Follow existing glassmorphism design language with neumorphic cards
- Use existing color palette: warm earthy tones, terracotta accents
- Heatmap colors should extend existing status colors (gray, orange, red)
- Charts should use Swift Charts for native iOS 16+ appearance
- Maintain accessibility with sufficient color contrast and VoiceOver support
- Date picker should be intuitive and not obstruct the main view

### Components to Reuse
- `NeumorphicCardStyle` for all cards and containers
- `SectionHeader` for section titles
- `BodyDiagramView` as base for heatmap overlay (may need to extract shared logic)
- `StatusBadge` for labels
- `WarmGradientBackground` for view background
- Existing `BodyLocation` enum and `PlacementLog` model
- `PrimaryButtonStyle` and `NeumorphicButtonStyle` for buttons

### Layout Structure
```
Patterns Tab
├── Header: "Rotation Patterns" + Share Button
├── Date Range Selector Card
│   ├── Preset Buttons (7d, 30d, 90d, All)
│   └── Custom Date Picker
├── Compliance Score Card
│   ├── Score Circle/Gauge
│   └── Explanation Text
├── Heatmap Body Diagram Card
│   ├── Front/Back Toggle
│   ├── Body Diagram with Overlay
│   └── Color Legend
├── Zone Statistics Card
│   └── Ranked List of Zones
├── Trend Chart Card
│   └── Time Series Chart
└── Location Breakdown Card
    └── Per-Location Chart
```

## Technical Considerations

### Data Model Additions
```swift
struct HeatmapData {
    let location: BodyLocation
    let usageCount: Int
    let intensity: Double // 0.0 - 1.0
    let lastUsed: Date?
    let percentageOfTotal: Double
}

struct RotationScore {
    let score: Int // 0-100
    let distributionScore: Int
    let restComplianceScore: Int
    let explanation: String
}
```

### ViewModel Extensions
- Add methods to `PlacementViewModel` or create new `PatternViewModel`
- `generateHeatmapData(from: Date, to: Date) -> [HeatmapData]`
- `calculateRotationScore(from: Date, to: Date) -> RotationScore`
- `getPlacementTrend(from: Date, to: Date, groupBy: DateGrouping) -> [TrendDataPoint]`
- Cache computed data to avoid recalculation on every view update

### Dependencies
- Swift Charts framework (iOS 16+) for charting
- No external dependencies required

### Performance Considerations
- Lazy load charts only when scrolled into view
- Cache heatmap calculations when date range unchanged
- Use `@Observable` for reactive updates
- Limit chart data points for large date ranges (aggregate by week/month)

### Export Implementation
- Use `ImageRenderer` (iOS 16+) to capture view as image
- Generate PDF using `UIGraphicsPDFRenderer`
- Include metadata: app version, export date, date range

## Success Metrics

- Users can identify their most/least used sites within 5 seconds of viewing heatmap
- Date range selection responds in under 500ms
- Compliance score helps users understand rotation effectiveness
- Export functionality successfully shares to common apps (Messages, Mail, Files)
- View loads in under 1 second even with 1+ year of placement history
- Users report increased awareness of rotation patterns (qualitative feedback)

## Open Questions

1. Should the compliance score algorithm weight recent placements more heavily than older ones?
2. Should we add haptic feedback when tapping zones on the heatmap?
3. What is the minimum number of placements needed to show a meaningful compliance score? (Suggest: 5+)
4. Should the exported PDF include recommendations based on the heatmap analysis?
5. Should there be an option to annotate or add notes to exported reports?
