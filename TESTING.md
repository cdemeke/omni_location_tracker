# Share Extension Feature

## Overview
This feature adds comprehensive sharing capabilities, allowing users to share site rotations, history summaries, and statistics via Messages, Mail, and other apps.

## Files Changed
- `OmniSiteTracker/Features/ShareExtensionSupport.swift` (new file)

## What This Feature Does
- Creates shareable content for various data types:
  - **Site rotations** - Individual site log entries
  - **History summaries** - List of recent rotations
  - **Statistics** - Personal tracking stats and streaks
- Formats content with emojis and clear structure
- Integrates with iOS Share Sheet (UIActivityViewController)
- Tracks recently shared items
- Configurable sharing options (include app link, emojis, format style)

## How to Test

### Prerequisites
- iOS Simulator or physical device
- App built and running
- Messages/Mail configured (for actual sharing)

### Test Steps

1. **Build and Run**
   - Open the project in Xcode
   - Build and run (Cmd+R)

2. **Navigate to Share Settings**
   - Find and open the Share Extension/Share Settings feature

3. **Review Share Settings UI**
   - Verify the header shows "Share Extension" info
   - Check the "Format Options" section:
     - Include App Link (toggle)
     - Include Emojis (toggle)
     - Default Format (picker: Standard/Compact/Detailed)

4. **Test Format Options**
   - Toggle "Include App Link" OFF
   - Toggle "Include Emojis" OFF
   - Change "Default Format" to "Compact"
   - Verify changes are reflected in UI

5. **Review What Can Be Shared**
   - Verify the section lists:
     - Individual site rotations
     - History summaries
     - Statistics and streaks
     - Export reports

6. **Test Sharing a Site Rotation** (if integrated)
   - Navigate to a logged site rotation in the app
   - Tap the Share button/option
   - Verify the share sheet appears with:
     - Formatted text including site name and date
     - App link (if enabled)
     - Emoji indicators (if enabled)

7. **Test Share Sheet Options**
   - In the share sheet, verify options include:
     - Messages
     - Mail
     - Copy
     - More options
   - Select "Copy"
   - Open Notes app and paste
   - Verify the formatted text is correct

8. **Review Recent Shares**
   - Return to Share Settings
   - Check the "Recent Shares" section
   - Verify recent shares are tracked (if any)

### Expected Results
- Share settings are displayed correctly
- Toggle options work (App Link, Emojis)
- Format picker changes between Standard/Compact/Detailed
- Share sheet appears with formatted content
- Content includes appropriate information based on settings
- Recent shares are tracked

### Edge Cases to Test
- Sharing when no data exists
- Sharing very long history (10+ entries)
- Changing settings and immediately sharing
- Canceling share mid-flow
- Sharing to different apps (Messages, Mail, Notes)

### Share Content Format Examples

**Site Rotation:**
```
📍 Site Rotation Log

Site: Abdomen - Left
Date: Jan 24, 2026 at 10:30 AM

Tracked with OmniSite Tracker
```

**Statistics:**
```
📈 My OmniSite Stats

Total Rotations: 47
Favorite Site: Upper Arm - Right
Current Streak: 12 days

Track your sites with OmniSite Tracker!
```
