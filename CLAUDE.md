# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build from command line
xcodebuild -project Styleum.xcodeproj -scheme Styleum -configuration Debug build

# Build for specific platform
xcodebuild -project Styleum.xcodeproj -scheme Styleum -destination 'platform=iOS Simulator,name=iPhone 16'

# Clean build
xcodebuild -project Styleum.xcodeproj -scheme Styleum clean
```

For day-to-day development, open `Styleum.xcodeproj` in Xcode and use Cmd+B to build, Cmd+R to run.

## Project Overview

Styleum is a SwiftUI app targeting multiple Apple platforms:
- iOS (iPhone/iPad)
- macOS
- visionOS

## Dependencies (Swift Package Manager)

- **Supabase** (supabase-swift 2.5.1+) - Backend services including Auth, Functions, PostgREST, Realtime, and Storage
- **GoogleSignIn** (9.0.0+) - Google authentication
- **Kingfisher** (8.6.2+) - Image loading and caching
- **KeychainAccess** - Secure credential storage

## Architecture

- Entry point: `StyleumApp.swift` - Standard SwiftUI App lifecycle with `@main`
- Main view: `ContentView.swift`
- Uses Swift 5 with modern concurrency features (`SWIFT_APPROACHABLE_CONCURRENCY`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)

## Configuration Notes

- Bundle ID: `com.sameerstudios.Styleum`
- App Sandbox enabled (macOS)
- Automatic code signing with Development Team
