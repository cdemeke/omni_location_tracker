# PRD: UI Redesign - Modern Wellness Aesthetic

## Introduction

Redesign the OmniSite Tracker app to use a cleaner, modern wellness-style aesthetic focused on reducing visual clutter and improving usability. The new design will feature a soft card-based layout with cool pastel colors, minimal shadows, generous spacing, and more interactive body diagram components. This redesign aims to create a calm, approachable interface that reduces cognitive load while maintaining all existing functionality.

## Goals

- Reduce visual clutter by removing heavy shadows, gradients, and neumorphic effects
- Implement a cool pastel color palette (soft blues, lavenders, mints) for a calming wellness feel
- Create generous whitespace and spacing to improve readability and touch targets
- Simplify card styles to flat backgrounds with minimal or no borders
- Make the body diagram more interactive with better visual feedback
- Maintain existing bottom tab navigation structure
- Ensure all touch targets are at least 44pt for accessibility
- Improve visual hierarchy through typography and spacing rather than shadows

## User Stories

### US-001: Create New Color Palette
**Description:** As a user, I want the app to use calming cool pastel colors so that the interface feels modern and wellness-focused.

**Acceptance Criteria:**
- [ ] Define new primary background color (soft off-white/very light gray ~#F8FAFC)
- [ ] Define new card background color (pure white or very subtle blue tint ~#FFFFFF)
- [ ] Define new primary accent color (soft blue ~#6B9FD4 or ~#7C9FD6)
- [ ] Define new secondary accent color (soft lavender ~#A78BBA or mint ~#7DCFB6)
- [ ] Define success color (soft mint green ~#7DCFB6)
- [ ] Define warning color (soft peach/coral ~#F4A683)
- [ ] Define text colors: primary (~#1E293B), secondary (~#64748B), muted (~#94A3B8)
- [ ] Remove all warm earthy tone color definitions
- [ ] Typecheck/lint passes

### US-002: Implement New Card Style
**Description:** As a user, I want cards to be clean and minimal so that content is easier to scan and the interface feels less busy.

**Acceptance Criteria:**
- [ ] Create new `SoftCardStyle` ViewModifier with flat white/light background
- [ ] Use large corner radius (20-24pt) for friendly rounded appearance
- [ ] Remove or minimize shadows (max 2-4pt blur, very low opacity ~0.04)
- [ ] Remove all gradient overlays and stroke borders from cards
- [ ] Add generous internal padding (20-24pt)
- [ ] Deprecate or remove `GlassCardStyle` modifier
- [ ] Deprecate or remove `NeumorphicCardStyle` modifier
- [ ] Update `.neumorphicCard()` extension to use new `SoftCardStyle`
- [ ] Typecheck/lint passes

### US-003: Update Typography System
**Description:** As a user, I want typography to be clean and highly readable so that information is easy to consume at a glance.

**Acceptance Criteria:**
- [ ] Use SF Pro Rounded (or system rounded) for all text where available
- [ ] Define consistent type scale: title (24pt), headline (18pt), body (16pt), caption (13pt)
- [ ] Increase line height/spacing for better readability
- [ ] Update `SectionHeader` component to use new typography (larger, bolder titles)
- [ ] Ensure minimum 16pt font size for primary content
- [ ] Typecheck/lint passes

### US-004: Create Pill Button Styles
**Description:** As a user, I want buttons to be pill-shaped and touch-friendly so that they are easy to tap and visually consistent.

**Acceptance Criteria:**
- [ ] Create new `PillButtonStyle` with full capsule/pill shape
- [ ] Primary variant: solid pastel accent fill, white text
- [ ] Secondary variant: light pastel fill (~10% opacity), accent text
- [ ] Outline variant: transparent with subtle border, accent text
- [ ] Minimum height of 48pt for touch accessibility
- [ ] Horizontal padding of 24-32pt
- [ ] Remove gradient fills from buttons - use solid colors
- [ ] Subtle scale animation on press (0.97)
- [ ] Update existing `PrimaryButtonStyle` and `NeumorphicButtonStyle`
- [ ] Typecheck/lint passes

### US-005: Update Background Style
**Description:** As a user, I want a clean, flat background so that the interface feels calm and uncluttered.

**Acceptance Criteria:**
- [ ] Replace `WarmGradientBackground` with flat pastel background
- [ ] Use single solid color or very subtle gradient (nearly imperceptible)
- [ ] Background color should be soft off-white/light gray (#F8FAFC or similar)
- [ ] Update all views using `WarmGradientBackground` to use new background
- [ ] Typecheck/lint passes

### US-006: Redesign Segmented Tab Control
**Description:** As a user, I want the front/back toggle to be a clean segmented control so that it matches the modern aesthetic.

**Acceptance Criteria:**
- [ ] Update `BodyViewTabs` to use flat design (no gradients)
- [ ] Selected state: solid pastel accent background, white text
- [ ] Unselected state: transparent background, muted text
- [ ] Container: subtle light gray pill background
- [ ] Smooth sliding indicator animation between segments
- [ ] Typecheck/lint passes

### US-007: Redesign Home Screen Layout
**Description:** As a user, I want the home screen to have clear visual hierarchy with generous spacing so that I can quickly find what I need.

**Acceptance Criteria:**
- [ ] Increase spacing between cards to 20-24pt
- [ ] Update recommendation card to use new soft card style
- [ ] Update body diagram section card to use new soft card style
- [ ] Update recent placement card to use new soft card style
- [ ] Update legend card to use new soft card style
- [ ] Ensure single-column vertical flow with consistent margins (20pt horizontal)
- [ ] Remove any remaining neumorphic/glass effects
- [ ] Typecheck/lint passes

### US-008: Enhance Body Diagram Interactivity
**Description:** As a user, I want the body diagram to provide better visual feedback when I interact with it so that I feel confident about my selections.

**Acceptance Criteria:**
- [ ] Add hover/highlight state when finger approaches a zone (if technically feasible)
- [ ] Add subtle pulse animation on recommended zone
- [ ] Increase touch target size for zone buttons to minimum 48x48pt
- [ ] Add haptic feedback on zone selection
- [ ] Show subtle glow or highlight ring around selected/tapped zone
- [ ] Smooth transition animation when switching between front/back views
- [ ] Zone buttons should have clear pressed state (slight scale + opacity change)
- [ ] Typecheck/lint passes

### US-009: Update Zone Button Design
**Description:** As a user, I want zone buttons on the body diagram to be clean and easy to tap so that logging placements is effortless.

**Acceptance Criteria:**
- [ ] Update zone buttons to use flat pastel backgrounds (color-coded by status)
- [ ] Remove gradient fills from zone buttons
- [ ] Use white text with adequate contrast
- [ ] Recommended zone: subtle animated border or glow effect (not heavy)
- [ ] Available zone: soft gray/blue pastel
- [ ] Recent zone: soft peach/coral pastel
- [ ] Rested zone: soft mint/green pastel
- [ ] Dotted connector lines should use lighter, more subtle color
- [ ] Typecheck/lint passes

### US-010: Redesign Recommendation Card
**Description:** As a user, I want the recommendation card to be prominent but not overwhelming so that I notice it without it dominating the screen.

**Acceptance Criteria:**
- [ ] Use soft card style with subtle accent tint for background
- [ ] Clear "Recommended" label with pill badge style
- [ ] Large, tappable area for the recommended zone
- [ ] Show location name prominently with supporting detail text below
- [ ] Include subtle icon (e.g., checkmark or star) for visual interest
- [ ] Remove heavy shadows or borders
- [ ] Typecheck/lint passes

### US-011: Redesign History Screen Layout
**Description:** As a user, I want the history screen to display placement records in clean, scannable cards so that I can quickly review my history.

**Acceptance Criteria:**
- [ ] Update history list items to use new soft card style
- [ ] Each card should show: location, date/time, and optional note
- [ ] Use color-coded dot or pill badge to indicate location
- [ ] Generous padding inside cards (16-20pt)
- [ ] Consistent spacing between list items (12-16pt)
- [ ] Update any filter/search UI to match new design system
- [ ] Typecheck/lint passes

### US-012: Redesign Patterns Screen Layout
**Description:** As a user, I want the patterns/analytics screen to present data in clean stat tiles and simple charts so that insights are easy to understand.

**Acceptance Criteria:**
- [ ] Update all section cards to use new soft card style
- [ ] Ensure consistent spacing between sections (20-24pt)
- [ ] Update date range picker to match new design system
- [ ] Clean up any heavy visual elements
- [ ] Typecheck/lint passes

### US-013: Redesign Compliance Score Display
**Description:** As a user, I want the rotation score to be displayed as a clean progress ring with stat tiles so that my compliance is easy to understand at a glance.

**Acceptance Criteria:**
- [ ] Update progress ring to use new accent colors
- [ ] Ring stroke should be thicker (8-10pt) for visibility
- [ ] Background ring should be very subtle light gray
- [ ] Score number displayed large and centered inside ring
- [ ] Sub-scores displayed as clean stat tiles below the ring
- [ ] Stat tiles: light background, bold number, subtle label
- [ ] Remove any gradient effects from the ring
- [ ] Typecheck/lint passes

### US-014: Redesign Heatmap Body Diagram
**Description:** As a user, I want the heatmap visualization to use a clean color scale so that usage patterns are clear without being visually harsh.

**Acceptance Criteria:**
- [ ] Update heatmap color scale to use softer pastel range
- [ ] Low usage: soft light gray or very light blue
- [ ] Medium usage: soft lavender or light purple
- [ ] High usage: soft coral or warm pink (not harsh red)
- [ ] Update `HeatmapLegend` to reflect new color scale
- [ ] Zone detail popover should use new soft card style
- [ ] Typecheck/lint passes

### US-015: Update Zone Statistics List
**Description:** As a user, I want zone statistics to be displayed as clean stat rows so that I can compare usage across zones easily.

**Acceptance Criteria:**
- [ ] Each zone row should have: icon, name, progress bar, count
- [ ] Progress bars should use soft pastel fills matching heatmap colors
- [ ] Progress bar background should be very light gray
- [ ] Clean typography with clear hierarchy (name bold, count regular)
- [ ] Generous row height for touch accessibility (48pt minimum)
- [ ] Typecheck/lint passes

### US-016: Update Charts and Data Visualization
**Description:** As a user, I want charts to be clean and minimal so that trends are easy to see without visual noise.

**Acceptance Criteria:**
- [ ] Update `UsageTrendChartView` to use new pastel colors
- [ ] Update `LocationBreakdownChartView` to use new pastel colors
- [ ] Remove or minimize grid lines (use very subtle if needed)
- [ ] Use rounded line caps and joins for line charts
- [ ] Bar charts should use soft rounded corners
- [ ] Ensure adequate spacing between chart and labels
- [ ] Typecheck/lint passes

### US-017: Update Status Badge Component
**Description:** As a user, I want status badges to be clean pill shapes so that they are easy to read and visually consistent.

**Acceptance Criteria:**
- [ ] Update `StatusBadge` to remove gradient fills
- [ ] Use solid pastel background colors
- [ ] Ensure adequate padding (horizontal 12pt, vertical 6pt)
- [ ] Text should be semibold for readability
- [ ] Maintain capsule/pill shape
- [ ] Typecheck/lint passes

### US-018: Update Confirmation Sheet Design
**Description:** As a user, I want the placement confirmation sheet to be clean and focused so that confirming a placement is quick and clear.

**Acceptance Criteria:**
- [ ] Update `PlacementConfirmationSheet` to use new background color
- [ ] Update buttons to use new pill button styles
- [ ] Confirm button: primary pill style with accent color
- [ ] Cancel button: secondary/outline pill style
- [ ] Clean typography for location name and details
- [ ] Generous spacing between elements
- [ ] Typecheck/lint passes

### US-019: Update Edit Sheet Design
**Description:** As a user, I want the placement edit sheet to match the new design system so that the experience is consistent throughout the app.

**Acceptance Criteria:**
- [ ] Update `PlacementEditSheet` to use new background color
- [ ] Update form fields to have clean, minimal styling
- [ ] Update buttons to use new pill button styles
- [ ] Ensure consistent padding and spacing
- [ ] Typecheck/lint passes

### US-020: Update Tab Bar Styling
**Description:** As a user, I want the bottom tab bar to match the new aesthetic so that navigation feels integrated with the overall design.

**Acceptance Criteria:**
- [ ] Tab bar background should be clean white or very light
- [ ] Selected tab icon: accent color
- [ ] Unselected tab icon: muted gray color
- [ ] Remove any heavy shadows from tab bar
- [ ] Ensure tab items have adequate touch targets
- [ ] Typecheck/lint passes

### US-021: Update Success Toast Design
**Description:** As a user, I want success messages to be clean and noticeable so that I have clear feedback when actions complete.

**Acceptance Criteria:**
- [ ] Update success toast to use soft mint/green background
- [ ] Clean white icon and text
- [ ] Pill/capsule shape with generous corner radius
- [ ] Subtle shadow (optional) for slight elevation
- [ ] Smooth slide-in animation
- [ ] Typecheck/lint passes

### US-022: Final Design System Cleanup
**Description:** As a developer, I want unused design components removed so that the codebase is clean and maintainable.

**Acceptance Criteria:**
- [ ] Remove deprecated color definitions from `DesignSystem.swift`
- [ ] Remove unused ViewModifiers (old neumorphic/glass styles)
- [ ] Remove unused button styles
- [ ] Ensure all views use the new design system consistently
- [ ] Add documentation comments to new design components
- [ ] Typecheck/lint passes

## Functional Requirements

- FR-1: All color definitions must be updated to use cool pastel palette
- FR-2: All cards must use flat backgrounds with minimal/no shadows
- FR-3: All buttons must use pill/capsule shape with solid fills
- FR-4: All touch targets must be minimum 44pt (preferably 48pt)
- FR-5: Spacing between major sections must be 20-24pt
- FR-6: Typography must use rounded font variants where available
- FR-7: Body diagram zones must provide haptic feedback on selection
- FR-8: Zone buttons must have clear visual states (default, pressed, recommended)
- FR-9: Front/back toggle must animate smoothly between states
- FR-10: Progress indicators must use clean ring style with accent colors
- FR-11: Charts must use pastel color palette consistent with design system
- FR-12: All gradient effects must be removed or replaced with solid colors

## Non-Goals (Out of Scope)

- Changing the app's navigation structure (keeping bottom tabs)
- Adding new features or functionality
- Changing the data model or backend logic
- Redesigning the app icon or launch screen
- Adding dark mode support (can be future enhancement)
- Changing the body diagram zone positions or logic
- Adding new screens or views
- Internationalization or localization changes

## Design Considerations

### Color Palette Reference
```
Background:        #F8FAFC (soft off-white)
Card Background:   #FFFFFF (white)
Primary Accent:    #6B9FD4 (soft blue)
Secondary Accent:  #A78BBA (soft lavender)
Success:           #7DCFB6 (soft mint)
Warning:           #F4A683 (soft peach)
Text Primary:      #1E293B (dark slate)
Text Secondary:    #64748B (slate gray)
Text Muted:        #94A3B8 (light slate)
```

### Typography Scale
```
Title:    SF Pro Rounded Bold, 24pt
Headline: SF Pro Rounded Semibold, 18pt
Body:     SF Pro Rounded Regular, 16pt
Caption:  SF Pro Rounded Regular, 13pt
```

### Spacing System
```
Card Internal Padding: 20-24pt
Section Spacing:       20-24pt
List Item Spacing:     12-16pt
Horizontal Margins:    20pt
```

### Component Patterns
- Cards: White background, 20-24pt corner radius, minimal shadow
- Buttons: Pill shape, 48pt height, solid fills
- Progress Rings: 8-10pt stroke, accent color, light gray background
- Stat Tiles: Light background, bold number, subtle label below

## Technical Considerations

- All changes should be made in `DesignSystem.swift` first, then propagated to views
- Use SwiftUI's built-in `.font(.system(.body, design: .rounded))` for rounded typography
- Haptic feedback should use `UIImpactFeedbackGenerator` with `.light` or `.medium` style
- Consider using `@Environment(\.colorScheme)` hooks for future dark mode support
- Test all color combinations for WCAG AA contrast compliance (4.5:1 for text)

## Success Metrics

- Visual consistency: All screens use the same card style, colors, and spacing
- Reduced visual complexity: Fewer shadows, gradients, and decorative elements
- Improved touch targets: All interactive elements are minimum 44pt
- Cleaner aesthetic: App feels calmer and more modern
- Code cleanliness: Deprecated design components removed

## Design Decisions (Clarified)

1. **Micro-animations:** Add subtle animations - fade-ins, gentle scaling on cards, smooth transitions
2. **Stat tiles:** Numbers with small icons for visual interest
3. **Body diagram silhouette:** Keep current gray/neutral silhouette (no color change)
4. **Sheets background:** Light frosted blur effect (subtle glass look) for confirmation/edit sheets

## Implementation Order

Work through screens sequentially:
1. **Phase 1:** Design system foundation (colors, cards, buttons, typography) - US-001 to US-006
2. **Phase 2:** Home screen redesign - US-007 to US-010
3. **Phase 3:** History screen redesign - US-011
4. **Phase 4:** Patterns screen redesign - US-012 to US-016
5. **Phase 5:** Shared components and cleanup - US-017 to US-022

## Open Questions

None - all major design decisions have been clarified.
