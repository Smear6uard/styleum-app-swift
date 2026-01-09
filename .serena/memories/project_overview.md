# Styleum Project Overview

## Purpose
Styleum is an AI-powered fashion/styling app that helps users manage their wardrobe and get outfit recommendations. Key features include:
- **Wardrobe Management**: Users can photograph and catalog their clothing items with AI analysis
- **Style Me**: AI-generated outfit suggestions based on user's wardrobe
- **Achievements/Gamification**: Streak tracking and achievements system
- **User Profiles**: Style preferences, onboarding style quiz

## Tech Stack
- **Language**: Swift 5 with modern concurrency (`async/await`, `@MainActor`)
- **UI Framework**: SwiftUI
- **Target Platforms**: iOS, macOS, visionOS
- **Backend**: Supabase (Auth, Functions, PostgREST, Realtime, Storage)
- **Authentication**: Google Sign-In + Supabase Auth
- **Image Loading**: Kingfisher
- **Secure Storage**: KeychainAccess

## Architecture Patterns
- **Observation**: Uses `@Observable` macro (iOS 17+) for state management
- **Services**: Singleton pattern with `shared` static instance (`AuthService.shared`, `WardrobeService`, etc.)
- **Navigation**: Centralized `AppCoordinator` managing tabs, sheets, and full-screen destinations
- **Repository Pattern**: `OutfitRepository` for data layer abstraction
- **Design System**: Centralized tokens in `DesignSystem/Tokens/` (AppColors, AppTypography, AppSpacing, etc.)

## Key Entry Points
- `StyleumApp.swift` - App entry point with `@main`
- `RootView.swift` - Authentication state routing
- `MainTabView.swift` - Main tab navigation
- `AppCoordinator.swift` - Navigation coordinator

## Bundle Information
- Bundle ID: `com.sameerstudios.Styleum`
- Development Team: Automatic signing
