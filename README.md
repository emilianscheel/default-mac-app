# Default App Manager

A native SwiftUI macOS menu bar app for changing the current user's Finder/open default app for curated file types.

## Build and Run

```sh
xcodebuild -project DefaultAppManager.xcodeproj -scheme DefaultAppManager -configuration Debug -derivedDataPath .build/DerivedData build
open ".build/DerivedData/Build/Products/Debug/Default App Manager.app"
```

The debug build uses stable ad-hoc local signing and no app sandbox. LaunchServices default-handler changes are per-user macOS preferences and do not require a special permission grant.
