# OmniSite Tracker

A SwiftUI iOS app for tracking and rotating insulin pump placement sites. Designed for Type 1 Diabetes patients and caregivers to maintain healthy site rotation habits.

## Features

- **Interactive Body Diagram** - Tap on anatomically accurate front/back body views to log placement sites
- **Smart Recommendations** - Get suggestions for the next optimal site based on rotation history
- **Placement History** - View complete history of all pump site changes
- **Site Status Tracking** - Visual indicators show recently used, recovering, and available sites

## Supported Placement Sites

- Left/Right Abdomen
- Lower Abdomen
- Left/Right Thigh
- Left/Right Arm (Back)
- Lower Back

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Architecture

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Local persistence for placement logs
- **MVVM** - Clean separation of concerns

## Project Structure

```
OmniSiteTracker/
├── Models/
│   ├── BodyLocation.swift      # Enum of valid placement sites
│   └── PlacementLog.swift      # SwiftData model for placements
├── Views/
│   ├── HomeView.swift          # Main dashboard
│   ├── HistoryView.swift       # Placement history list
│   └── Components/
│       ├── BodyDiagramView.swift
│       ├── RecommendationCard.swift
│       └── PlacementConfirmationSheet.swift
├── ViewModels/
│   └── PlacementViewModel.swift
└── Utilities/
    └── DesignSystem.swift      # Colors and styling
```

## License

MIT
