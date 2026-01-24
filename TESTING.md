# QR Code Sharing Feature

## Overview
This feature adds QR code generation and scanning capabilities for quickly sharing site rotation data between devices or users.

## Files Changed
- `OmniSiteTracker/Features/QRCodeSharingView.swift` (new file)

## Important: Feature Not Yet Integrated

**This feature is NOT yet accessible from the main app navigation.** The view exists but needs to be connected to the app's UI. Choose one of the testing methods below:

---

## Method 1: Use SwiftUI Preview (Easiest)

1. Open `OmniSiteTracker/Features/QRCodeSharingView.swift` in Xcode
2. In the Editor, click **Canvas** in the top-right (or press **Opt+Cmd+Return**)
3. The preview will show the QR Code Sharing view
4. Click **Live Preview** (play button) to interact with it

---

## Method 2: Temporarily Add to Settings (Full Testing)

To test the feature within the running app, temporarily add it to SettingsView:

1. Open `OmniSiteTracker/Views/SettingsView.swift`

2. Find the `aboutSection` property (around line 609) and add a new section before it. Add this code inside the `VStack(spacing: 24)` in the body, before `aboutSection`:

```swift
// MARK: - QR Code Sharing Section (Temporary for Testing)
NavigationLink(destination: QRCodeSharingView()) {
    HStack {
        Image(systemName: "qrcode")
            .foregroundColor(.appAccent)
        Text("QR Code Sharing")
        Spacer()
        Image(systemName: "chevron.right")
            .foregroundColor(.textSecondary)
    }
    .padding(16)
    .neumorphicCard()
}
```

3. Build and run the app
4. Go to the **Settings** tab
5. Scroll down and tap **"QR Code Sharing"**

---

## Test Steps (Once Accessible)

### Test QR Code Generation
1. Tap **"Generate QR Code"**
2. Select a site from the picker (e.g., "Upper Arm - Left")
3. Tap **"Generate"**
4. Verify a QR code image appears
5. Tap **"Share"** and verify the share sheet opens

### Test QR Code Scanning (Physical Device Only)
1. Go back and tap **"Scan QR Code"**
2. Grant camera permission when prompted
3. Point camera at a QR code generated from this app
4. Verify the scanned data appears in an alert

### Expected Results
- QR codes generate correctly with site data encoded
- Share sheet allows exporting the QR image
- Scanner detects and reads QR codes
- Valid OmniTracker QR codes show parsed site/date info
- Invalid QR codes show "Unknown QR code format"

---

## What This Feature Does
- Generates QR codes containing site rotation data
- Encodes data as JSON in custom URL scheme (`omnitracker://`)
- Supports two payload types:
  - **Site data** - Site name and date
  - **Profile data** - Profile ID and name
- Scans QR codes using device camera
- Parses and validates scanned QR codes
