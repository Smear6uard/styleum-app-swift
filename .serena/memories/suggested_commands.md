# Suggested Commands for Styleum Development

## Build Commands (Xcode CLI)

```bash
# Standard debug build
xcodebuild -project Styleum.xcodeproj -scheme Styleum -configuration Debug build

# Build for iOS Simulator
xcodebuild -project Styleum.xcodeproj -scheme Styleum -destination 'platform=iOS Simulator,name=iPhone 16'

# Clean build folder
xcodebuild -project Styleum.xcodeproj -scheme Styleum clean

# Clean and rebuild
xcodebuild -project Styleum.xcodeproj -scheme Styleum clean build
```

## Xcode IDE (Recommended for daily dev)
- Open project: `open Styleum.xcodeproj`
- Build: Cmd+B
- Run: Cmd+R
- Clean: Cmd+Shift+K

## Git Commands
```bash
git status          # Check working tree status
git diff            # View unstaged changes
git log --oneline   # View commit history
git add .           # Stage all changes
git commit -m "msg" # Commit staged changes
```

## File System (macOS/Darwin)
```bash
ls -la              # List files with details
find . -name "*.swift" -type f  # Find Swift files
grep -r "pattern" --include="*.swift" .  # Search in Swift files
```

## Notes
- No automated test suite configured (no XCTest targets visible)
- No SwiftLint or other linting tools configured
- No SwiftFormat or other formatting tools configured
