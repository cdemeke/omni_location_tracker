# Changelog

All notable changes to OmniSite Tracker will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-23

### Added

- **Visual Body Diagram** - Interactive front and back body views with 9 default placement sites
- **Smart Recommendations** - Algorithm suggests optimal next site based on rest time and rotation balance
- **Placement Logging** - Tap to log with optional notes and one-tap confirmation
- **Placement History** - Complete chronological log with edit and delete capabilities
- **Heatmap Visualization** - Visual representation of site usage frequency across body zones
- **Compliance Scoring** - Rotation compliance score (0-100%) to track rotation habits
- **Color-Coded Status System**
  - Gray: Available (never used or fully rested)
  - Orange: Recent (used within recommended rest period)
  - Green: Rested (ready for use again)
- **Configurable Rest Period** - Adjust minimum rest days (default: 18 days)
- **Custom Sites** - Add unlimited custom body sites with custom names and SF Symbol icons
- **Site Management** - Enable/disable individual body sites to match preferences
- **History Display Preferences** - Option to show/hide disabled sites in History and Patterns views
- **Notification Reminders** - Get notified when sites become available
- **Export & Sharing** - Export patterns as images or PDF reports for healthcare team
- **Privacy-First Design** - All data stored locally, no accounts, no tracking
- **Warm Glassmorphism UI** - Modern design with earthy tones and smooth animations
- **Marketing Website** - Landing page, privacy policy, and support pages

### Technical

- Built with SwiftUI and iOS 17+ features
- SwiftData for local persistence
- MVVM architecture
- Supports iPhone SE through iPhone 15 Pro Max

---

## [Unreleased]

### Planned

- iCloud sync across devices
- Apple Watch companion app
- HealthKit integration
- Data export to CSV
- Multi-user/family accounts
- Localization (Spanish, German, French)
