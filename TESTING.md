# Site History Chart Feature

## Overview
This feature adds visual charts for site usage history, allowing users to see their rotation patterns over time using bar and pie charts.

## Files Changed
- `OmniSiteTracker/Features/SiteHistoryChartView.swift` (new file)

## What This Feature Does
- Displays site usage statistics using SwiftUI Charts
- **Time Range Selector**: Filter data by 7, 30, or 90 days
- **Chart Type Selector**: Switch between Bar chart and Pie chart views
- **Bar Chart**: Shows usage count per site as vertical bars
- **Pie Chart**: Shows proportional usage as a donut chart
- **Details List**: Shows exact usage counts per site
- Uses SwiftData to query placement history

## Important: Feature Not Yet Integrated

**This feature is NOT yet accessible from the main app navigation.** The view exists but needs to be connected to the app's UI. Choose one of the testing methods below:

---

## Method 1: Use SwiftUI Preview (Easiest)

1. Open `OmniSiteTracker/Features/SiteHistoryChartView.swift` in Xcode
2. Show the Canvas (**Option+Cmd+Return** or click "Canvas" in top-right)
3. Click **Live Preview** (play button) to interact with it

**Note**: Preview may show empty charts since there's no sample data in preview mode.

---

## Method 2: Temporarily Add to Patterns Tab (Full Testing)

To test with real data, add it to the PatternsView:

1. Open `OmniSiteTracker/Views/PatternsView.swift`

2. Find a suitable place in the view (e.g., in the toolbar or as a NavigationLink) and add:

```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        if #available(iOS 16.0, *) {
            NavigationLink(destination: SiteHistoryChartView()) {
                Image(systemName: "chart.bar.xaxis")
            }
        }
    }
}
```

3. Build and run the app
4. Go to the **Patterns** tab
5. Tap the chart icon in the top-right

---

## Method 3: Temporarily Add to Settings

1. Open `OmniSiteTracker/Views/SettingsView.swift`

2. Add this inside the main `VStack(spacing: 24)`, before `aboutSection`:

```swift
// MARK: - Usage Charts (Temporary for Testing)
if #available(iOS 16.0, *) {
    NavigationLink(destination: SiteHistoryChartView()) {
        HStack {
            Image(systemName: "chart.pie")
                .foregroundColor(.appAccent)
            Text("Usage Charts")
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.textSecondary)
        }
        .padding(16)
        .neumorphicCard()
    }
}
```

3. Build and run, then find it in the **Settings** tab

---

## Test Steps (Once Accessible)

### Prerequisites
- Some placement history data (log a few site rotations first)
- iOS 16.0 or later (SwiftUI Charts requirement)

### Test Time Range Selector
1. Open the Usage Charts view
2. Verify the segmented control shows: "7 Days", "30 Days", "90 Days"
3. Tap each option and verify the chart updates
4. "7 Days" should show less data than "90 Days"

### Test Chart Type Toggle
1. Verify the chart type picker shows: "Bar" and "Pie"
2. With "Bar" selected, verify a bar chart is displayed
3. Tap "Pie" and verify it switches to a donut/pie chart
4. Each site should have a different color

### Test Details Section
1. Scroll down to the "Details" section
2. Verify each site is listed with its usage count
3. Sites should be sorted by usage (highest first)

### Expected Results
- Time range filters the data correctly
- Bar chart shows sites on X-axis, counts on Y-axis
- Pie chart shows proportional usage with inner radius (donut style)
- Details list matches the chart data
- Colors are consistent between chart and legend

---

## Edge Cases to Test
- No placement data (should show empty chart)
- Single site used (pie chart should show 100%)
- All sites used equally
- Changing time range with different data densities
