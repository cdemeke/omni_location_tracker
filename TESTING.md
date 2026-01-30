# Voice Commands Feature

## Overview
This feature adds voice command recognition for hands-free operation of the app. Users can speak commands to perform common actions without touching the screen.

## Files Changed
- `OmniSiteTracker/Features/VoiceCommandsView.swift` (new file)

## What This Feature Does
- Integrates iOS Speech Recognition framework for voice input
- Supports the following voice commands:
  - **"log site"** - Opens the site logger
  - **"show history"** - Displays rotation history
  - **"view stats"** - Shows statistics dashboard
  - **"help"** - Lists available commands
- Provides real-time transcription feedback
- Manages microphone permissions

## How to Test

### Prerequisites
- A physical iOS device (voice recognition does not work well in Simulator)
- Microphone access permission

### Test Steps

1. **Build and Run**
   - Open the project in Xcode
   - Select a physical device as the target
   - Build and run (Cmd+R)

2. **Navigate to Voice Commands**
   - Find and tap on the Voice Commands feature in the app

3. **Grant Permissions**
   - When prompted, allow microphone and speech recognition access
   - Verify the status shows "Ready" (not "Permission needed")

4. **Test Voice Recognition**
   - Tap "Start Listening"
   - Speak clearly: "log site"
   - Verify the recognized text appears on screen
   - Verify a checkmark appears next to the "log site" command

5. **Test All Commands**
   - Repeat for each command: "show history", "view stats", "help"
   - Verify each command is recognized and highlighted

6. **Test Stop Functionality**
   - While listening, tap "Stop"
   - Verify the button changes back to "Start Listening"

### Expected Results
- Voice input is transcribed in real-time
- Commands are recognized and highlighted with a green checkmark
- Starting/stopping listening works without crashes

### Edge Cases to Test
- Speaking when permissions are denied
- Background noise handling
- Rapid start/stop cycles
