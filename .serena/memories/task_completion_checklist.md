# Task Completion Checklist

When completing a coding task in Styleum, verify the following:

## Before Committing

### Code Quality
- [ ] Code follows existing naming conventions (camelCase properties, PascalCase types)
- [ ] Uses design system tokens (`AppColors`, `AppTypography`, `AppSpacing`) instead of hardcoded values
- [ ] New services follow singleton pattern with `@Observable` if needed
- [ ] Async operations use `async/await` pattern
- [ ] UI code uses `@MainActor` when appropriate

### Build Verification
```bash
# Verify the build compiles
xcodebuild -project Styleum.xcodeproj -scheme Styleum -configuration Debug build
```

### SwiftUI Conventions
- [ ] Navigation uses `AppCoordinator` methods (`navigate(to:)`, `present(_:)`, `switchTab(to:)`)
- [ ] Haptic feedback via `HapticManager.shared` for user interactions
- [ ] Loading/error states handled appropriately

### Model Changes
- [ ] CodingKeys enum updated if adding new properties with snake_case backend names
- [ ] Optional types used appropriately for nullable backend fields
- [ ] Computed properties for derived values

## No Automated Tests
Note: This project does not currently have automated tests. Manual verification in simulator is the primary testing method.

## No Linting/Formatting Tools
No SwiftLint or SwiftFormat configured. Follow existing code style by example.

## Git Commit Guidelines
- Use clear, descriptive commit messages
- Reference any relevant issue numbers if applicable
- Keep commits focused on single logical changes
