# Default Mac App

<img src="./header.png" alt="Default Mac App" width="100%">

A native SwiftUI macOS menu bar app for changing the current user's Finder/open default app for curated file types.

## Build and Run

```sh
xcodebuild -project DefaultAppManager.xcodeproj -scheme DefaultAppManager -configuration Debug -derivedDataPath .build/DerivedData build
open ".build/DerivedData/Build/Products/Debug/Default Mac App.app"
```
