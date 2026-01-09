# Codebase Structure

```
Styleum/
├── App/
│   ├── StyleumApp.swift          # @main entry point
│   └── Configuration/
│       └── Config.swift          # Environment config (API keys, etc.)
│
├── Navigation/
│   ├── AppCoordinator.swift      # Centralized navigation state
│   ├── MainTabView.swift         # Tab bar container
│   └── TabBar.swift              # Custom tab bar UI
│
├── Features/                     # Feature modules (vertical slices)
│   ├── Auth/
│   │   ├── RootView.swift        # Auth state routing
│   │   ├── LoginScreen.swift
│   │   └── SplashView.swift
│   ├── Home/
│   │   └── HomeScreen.swift
│   ├── Wardrobe/
│   │   ├── WardrobeScreen.swift
│   │   ├── AddItemSheet.swift
│   │   ├── ItemDetailScreen.swift
│   │   └── CameraView.swift
│   ├── StyleMe/
│   │   ├── StyleMeScreen.swift
│   │   ├── OutfitResultsView.swift
│   │   ├── OutfitDetailScreen.swift
│   │   ├── AIProcessingView.swift
│   │   └── ...
│   ├── Profile/
│   │   ├── ProfileScreen.swift
│   │   ├── SettingsScreen.swift
│   │   ├── EditProfileScreen.swift
│   │   └── SubscriptionScreen.swift
│   ├── Achievements/
│   │   └── AchievementsScreen.swift
│   ├── Onboarding/
│   │   ├── OnboardingContainerView.swift
│   │   ├── StyleSwipeView.swift
│   │   └── ...
│   └── Sharing/
│       └── OutfitShareCardView.swift
│
├── Models/
│   ├── WardrobeItem.swift
│   ├── Outfit.swift
│   ├── Profile.swift
│   ├── Achievement.swift
│   └── Enums/
│       ├── ClothingCategory.swift
│       ├── StyleBucket.swift
│       └── ...
│
├── Services/
│   ├── AuthService.swift         # Authentication (Google + Supabase)
│   ├── WardrobeService.swift     # Wardrobe CRUD operations
│   ├── ProfileService.swift      # User profile management
│   ├── StyleumAPI.swift          # Backend API calls
│   ├── SupabaseManager.swift     # Supabase client singleton
│   ├── AchievementsService.swift
│   ├── StreakService.swift
│   └── LocationService.swift
│
├── Repositories/
│   └── OutfitRepository.swift    # Data layer for outfits
│
├── DesignSystem/
│   ├── Tokens/
│   │   ├── AppColors.swift       # Color palette
│   │   ├── AppTypography.swift   # Font styles
│   │   ├── AppSpacing.swift      # Spacing constants
│   │   ├── AppShadows.swift      # Shadow styles
│   │   └── AppAnimations.swift   # Animation presets
│   └── Components/
│       ├── AppButton.swift
│       ├── AppCard.swift
│       ├── AppTextField.swift
│       └── ... (reusable UI components)
│
├── Core/
│   ├── Extensions/               # Swift/SwiftUI extensions
│   ├── Haptics/
│   │   └── HapticManager.swift
│   ├── Networking/
│   │   └── JSONDecoders.swift
│   └── MatchedGeometry/
│       └── NamespaceKeys.swift
│
├── Resources/
│   └── (assets, localization, etc.)
│
├── Assets.xcassets/              # Image and color assets
├── fonts/                        # Custom fonts
└── Info.plist                    # App configuration
```

## Key Architectural Notes

1. **Feature Modules**: Each feature is self-contained with its screens and components
2. **Services Layer**: Business logic in singleton services with `@Observable` state
3. **Navigation**: Centralized via `AppCoordinator` - no distributed navigation state
4. **Design System**: All UI styling through design tokens, not hardcoded values
5. **Models**: Data models with Codable for Supabase integration
