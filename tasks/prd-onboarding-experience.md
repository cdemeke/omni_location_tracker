# PRD: First-Time Onboarding Experience

## Introduction

Create a first-time onboarding experience that welcomes new users to OmniSite Tracker, educates them on why insulin pump site rotation matters for their health, and teaches them how to use the app's features effectively. The onboarding uses a swipe-through carousel format with user-selectable topics for deeper learning, contextual help tooltips throughout the app, and is fully skippable and re-accessible.

## Goals

- Welcome new users and build confidence in using the app
- Educate users on the medical importance of proper site rotation (lipohypertrophy prevention, insulin absorption, tissue healing)
- Teach core app functionality: logging placements, understanding status colors, and using recommendations
- Provide optional deep-dives into advanced features (patterns, heatmaps, compliance scores)
- Enable users to revisit onboarding content at any time
- Support contextual help throughout the app for progressive learning

## User Stories

### US-001: Detect First-Time Launch
**Description:** As a new user, I want the app to automatically show onboarding on my first launch so that I can learn how to use it.

**Acceptance Criteria:**
- [ ] Store `hasCompletedOnboarding` flag in UserDefaults
- [ ] Check flag on app launch in OmniSiteTrackerApp.swift
- [ ] Show OnboardingView when flag is false
- [ ] Set flag to true when onboarding is completed or skipped
- [ ] Typecheck passes

### US-002: Create Onboarding Container View
**Description:** As a user, I want a clean carousel-style onboarding flow so that I can swipe through introduction screens at my own pace.

**Acceptance Criteria:**
- [ ] Create OnboardingView.swift with TabView and PageTabViewStyle
- [ ] Support 5 onboarding pages with smooth swipe transitions
- [ ] Show page indicator dots at bottom of screen
- [ ] Include "Skip" button in top-right corner on all screens
- [ ] Include "Next" button to advance pages
- [ ] Show "Get Started" button on final page
- [ ] Use app's design system (colors, typography, card styles)
- [ ] Typecheck passes

### US-003: Welcome Screen (Page 1)
**Description:** As a new user, I want a welcoming first screen so that I feel confident the app will help me.

**Acceptance Criteria:**
- [ ] Display app icon/logo prominently
- [ ] Show welcoming headline: "Welcome to OmniSite Tracker"
- [ ] Display brief tagline: "Smart site rotation for better insulin absorption"
- [ ] Include friendly illustration or icon representing the app's purpose
- [ ] Use appAccent color for visual emphasis
- [ ] Typecheck passes

### US-004: Why Rotation Matters Screen (Page 2)
**Description:** As a user, I want to understand why site rotation is important so that I'm motivated to use the app consistently.

**Acceptance Criteria:**
- [ ] Headline: "Why Site Rotation Matters"
- [ ] Display 3-4 key benefits with icons:
  - Prevents lipohypertrophy (fatty lumps)
  - Maintains consistent insulin absorption
  - Reduces scarring and tissue damage
  - Extends usable sites for long-term pump use
- [ ] Use soft card style for benefit items
- [ ] Keep text concise and scannable
- [ ] Typecheck passes

### US-005: How to Log a Placement Screen (Page 3)
**Description:** As a user, I want to learn how to log placements so that I can start tracking immediately.

**Acceptance Criteria:**
- [ ] Headline: "Logging a Placement"
- [ ] Show simplified body diagram illustration
- [ ] Explain the tap-to-select flow with numbered steps:
  1. Tap a zone on the body diagram
  2. Confirm the placement
  3. Optionally add a note
- [ ] Mention the recommendation card feature
- [ ] Use visual callouts or arrows pointing to UI elements
- [ ] Typecheck passes

### US-006: Understanding Status Colors Screen (Page 4)
**Description:** As a user, I want to understand what the zone colors mean so that I can make informed placement decisions.

**Acceptance Criteria:**
- [ ] Headline: "Understanding Site Status"
- [ ] Display color legend with explanations:
  - Gray (Available): Never used or fully rested - safe to use
  - Orange (Recent): Used recently - should avoid
  - Green (Rested): Previously used but recovered - ready again
- [ ] Show visual example of colored zones
- [ ] Explain how the app recommends the best site
- [ ] Typecheck passes

### US-007: Explore More Features Screen (Page 5)
**Description:** As a user, I want to know about additional features so that I can explore them when ready.

**Acceptance Criteria:**
- [ ] Headline: "Discover More Features"
- [ ] Display selectable topic cards for optional deep-dive:
  - "View Your History" - placement log and editing
  - "Track Your Patterns" - analytics and insights
  - "Understand Your Score" - compliance metrics
  - "Heatmap Visualization" - usage patterns
- [ ] Tapping a topic card opens a detail sheet with more info
- [ ] Topics are optional - user can skip directly to "Get Started"
- [ ] Show "Get Started" button prominently
- [ ] Typecheck passes

### US-008: Create Topic Detail Sheets
**Description:** As a user, I want to tap on feature topics to learn more so that I can understand advanced features at my own pace.

**Acceptance Criteria:**
- [ ] Create OnboardingTopicSheet view for detailed explanations
- [ ] History topic: explains placement log, filtering, editing/deleting
- [ ] Patterns topic: explains analytics tab, date range filtering
- [ ] Compliance topic: explains rotation score calculation, what good scores mean
- [ ] Heatmap topic: explains color scale, identifying overused areas
- [ ] Each sheet has a "Got it" dismiss button
- [ ] Use .presentationDetents([.medium]) for sheets
- [ ] Typecheck passes

### US-009: Add Help Button to Settings/Navigation
**Description:** As a user, I want to access onboarding again from settings so that I can refresh my knowledge anytime.

**Acceptance Criteria:**
- [ ] Add "Help & Tutorial" option in app (Settings or navigation menu)
- [ ] Tapping opens the full onboarding flow
- [ ] Onboarding can be dismissed at any point
- [ ] Works the same as first-time onboarding
- [ ] Typecheck passes

### US-010: Add Contextual Help Tooltips - Home Screen
**Description:** As a user, I want contextual help tips on the home screen so that I can learn features in context.

**Acceptance Criteria:**
- [ ] Add small "?" help button near the recommendation card
- [ ] Tapping shows tooltip: "This suggests the best site based on your rotation history"
- [ ] Add help button near body diagram section header
- [ ] Tapping shows tooltip: "Tap any zone to log a new placement. Colors show site status."
- [ ] Add help button near legend card
- [ ] Tooltips dismiss on tap outside or "Got it" button
- [ ] Use subtle styling that doesn't clutter the UI
- [ ] Typecheck passes

### US-011: Add Contextual Help Tooltips - History Screen
**Description:** As a user, I want contextual help on the history screen so that I understand how to manage my records.

**Acceptance Criteria:**
- [ ] Add help button near history list header
- [ ] Tooltip explains: "Your complete placement history. Tap any entry to edit or delete."
- [ ] Tooltip appears for first-time visitors to History tab (one-time)
- [ ] Store `hasSeenHistoryHelp` flag to show tip only once
- [ ] Typecheck passes

### US-012: Add Contextual Help Tooltips - Patterns Screen
**Description:** As a user, I want contextual help on the patterns screen so that I understand the analytics.

**Acceptance Criteria:**
- [ ] Add help button near compliance score section
- [ ] Tooltip explains score calculation briefly
- [ ] Add help button near heatmap section
- [ ] Tooltip explains: "Warmer colors = more frequently used. Aim for even distribution."
- [ ] Store `hasSeenPatternsHelp` flag to show tip only once
- [ ] Typecheck passes

### US-013: Create Reusable Tooltip Component
**Description:** As a developer, I need a reusable tooltip component so that contextual help is consistent throughout the app.

**Acceptance Criteria:**
- [ ] Create HelpTooltip view component in Components folder
- [ ] Accept title and message parameters
- [ ] Use popover or overlay presentation
- [ ] Style with frosted glass background (.ultraThinMaterial)
- [ ] Include dismiss button or tap-outside-to-dismiss
- [ ] Animate in/out smoothly
- [ ] Typecheck passes

### US-014: Create Help Button Component
**Description:** As a developer, I need a reusable help button so that contextual help triggers are consistent.

**Acceptance Criteria:**
- [ ] Create HelpButton view component
- [ ] Use "questionmark.circle" SF Symbol
- [ ] Style with textMuted color, subtle size (16-20pt)
- [ ] Accept onTap closure for triggering tooltips
- [ ] Include subtle press animation
- [ ] Typecheck passes

## Functional Requirements

- FR-1: App must detect first-time launch and show onboarding automatically
- FR-2: Onboarding must be a 5-page swipe carousel with page indicators
- FR-3: Every onboarding page must have a visible "Skip" button
- FR-4: Final onboarding page must have a "Get Started" button that dismisses onboarding
- FR-5: Page 5 must display selectable topic cards that open detail sheets
- FR-6: Onboarding completion/skip must persist across app restarts
- FR-7: Users must be able to re-access onboarding from a Help menu
- FR-8: Contextual help tooltips must be available on Home, History, and Patterns screens
- FR-9: First-time tab visits should show a one-time contextual tip (History, Patterns)
- FR-10: All tooltips must be dismissible with tap-outside or explicit button

## Non-Goals (Out of Scope)

- Video or animation-based tutorials (using static illustrations instead)
- User account creation or sign-in during onboarding
- Personalization questions (patient vs. caregiver persona)
- Interactive walkthrough with highlighted UI elements (using carousel instead)
- Push notification permission requests during onboarding
- In-app guided tours with step-by-step overlays
- Localization/internationalization of onboarding content

## Design Considerations

- **Visual Style:** Match the existing wellness aesthetic - soft pastels, rounded fonts, soft card styles
- **Illustrations:** Use SF Symbols and simple iconography; consider custom illustrations for body diagram preview
- **Typography:** Use .system(.title, design: .rounded) for headlines, .body for descriptions
- **Spacing:** Generous padding (24pt between sections) for calm, uncluttered feel
- **Colors:** Use appAccent for emphasis, textPrimary/textSecondary for content hierarchy
- **Animations:** Subtle page transitions, smooth tooltip fade-in/out

### Suggested Screen Layout

```
┌─────────────────────────────────┐
│                         [Skip] │
│                                 │
│         [Illustration]          │
│                                 │
│      Headline Text Here         │
│                                 │
│    Body text explaining the     │
│    concept in 2-3 lines max     │
│                                 │
│         • • ○ • •               │  <- Page indicators
│                                 │
│         [ Next → ]              │
└─────────────────────────────────┘
```

## Technical Considerations

- **State Management:** Use `@AppStorage` for UserDefaults flags (hasCompletedOnboarding, hasSeenHistoryHelp, etc.)
- **View Structure:** OnboardingView should be presented as a fullScreenCover from the root
- **Reusability:** Tooltip and HelpButton components should be generic for use across all screens
- **Performance:** Onboarding images/icons should be lightweight SF Symbols or asset catalog images
- **Accessibility:** All onboarding content should support VoiceOver with proper labels

## Success Metrics

- Users complete onboarding (don't skip) at least 60% of the time
- Users who complete onboarding log their first placement within the same session
- Help tooltips are tapped by at least 20% of users in first week
- Re-access of onboarding from Help menu indicates feature discoverability

## Open Questions

1. Should we track onboarding analytics (completion rate, time spent, topics viewed)?
2. Should the "Why Rotation Matters" content link to external medical resources?
3. Should we add a "Don't show again" option for contextual tooltips?
4. Should onboarding include a prompt to log their first placement as part of the flow?
5. What illustrations or icons should represent each onboarding concept?
