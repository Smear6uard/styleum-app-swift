# Code Style & Conventions

## Naming Conventions
- **Types**: PascalCase (`WardrobeItem`, `AuthService`, `AppCoordinator`)
- **Properties/Variables**: camelCase (`currentUser`, `isAuthenticated`, `selectedTab`)
- **Functions**: camelCase with verb prefix (`checkSession()`, `signInWithGoogle()`, `navigate(to:)`)
- **Enums**: PascalCase type, camelCase cases (`Tab.styleMe`, `Destination.itemDetail`)
- **Constants**: camelCase within enums (`AppColors.textPrimary`, `AppTypography.bodyMedium`)

## Swift Patterns

### Services
- Singleton pattern with `static let shared`
- `@Observable` macro for reactive state
- `@MainActor` for UI-bound services
- Async/await for all network operations

```swift
@Observable
final class AuthService {
    static let shared = AuthService()
    private init() { }
}
```

### Models
- Struct-based with `Codable`, `Identifiable`, `Equatable`, `Hashable`
- CodingKeys enum for snake_case ↔ camelCase mapping
- Computed properties for derived values

```swift
struct WardrobeItem: Codable, Identifiable, Equatable, Hashable {
    let id: String
    // ...
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}
```

### Views
- SwiftUI with `@Observable` bindings
- Navigation via `AppCoordinator`
- Design tokens from `AppColors`, `AppTypography`, `AppSpacing`

## Design System Usage
- Colors: `AppColors.textPrimary`, `AppColors.background`, `AppColors.slate`
- Typography: `AppTypography.headingMedium`, `AppTypography.bodySmall`
- Spacing: Use `AppSpacing` tokens
- Components: Reusable views in `DesignSystem/Components/`

## Documentation Style
- MARK comments for sections: `// MARK: - Section Name`
- Inline comments with emoji prefixes for debugging: `print("🔐 [AUTH] message")`
- No formal docstrings/documentation comments required

## Error Handling
- Custom error enums conforming to `LocalizedError`
- Async throws pattern for fallible operations
- Optional chaining and nil coalescing preferred
