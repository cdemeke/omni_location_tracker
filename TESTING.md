# Contextual Menus Feature

## Overview
This feature adds context menus (long-press menus) throughout the app, providing quick access to common actions for sites, placements, and history items.

## Files Changed
- `OmniSiteTracker/Features/ContextualMenusView.swift` (new file)

## What This Feature Does
- Adds long-press context menus to site list items
- Provides quick actions: Log Site, Add to Favorites, Share, Hide Site
- Includes context menus for placement logs: Edit, Share, Add Note, Delete
- Adds history-level context menu: Export, Filter, Sort
- Provides a reusable `standardContextMenu` view modifier for consistent menus

## How to Test

### Prerequisites
- iOS Simulator or physical device
- App built and running

### Test Steps

1. **Build and Run**
   - Open the project in Xcode
   - Build and run (Cmd+R)

2. **Navigate to Context Menus Demo**
   - Find the Contextual Menus feature in the app

3. **Test Site Context Menu**
   - Long-press on any site in the list (e.g., "Abdomen - Left")
   - Verify a context menu appears with options:
     - Log Site
     - Add to Favorites
     - Share
     - Hide Site (destructive/red)
   - Tap "Log Site" and verify the alert shows "Logged: [site name]"

4. **Test Favorite Action**
   - Long-press on a site again
   - Tap "Add to Favorites"
   - Verify the alert shows "Added to favorites: [site name]"

5. **Test Quick Actions Context Menu**
   - Long-press on any item in the "Quick Actions" section
   - Verify menu shows: Run Action, Add to Shortcuts, Info

6. **Test Selection**
   - Tap (not long-press) on a site
   - Verify a checkmark appears next to the selected site

### Expected Results
- Long-press on any list item shows a context menu
- Menu options are clearly labeled with icons
- Destructive actions appear in red
- Actions trigger appropriate feedback (alerts)

### Edge Cases to Test
- Long-press duration (should appear after ~0.5 seconds)
- Menu dismissal by tapping outside
- Rapid long-press on different items
