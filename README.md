<img src="./assets/header.png" alt="Default Mac App" width="100%">

# Default Mac App

A native SwiftUI macOS menu bar app for changing the current user's Finder/open default app for every file type.

[Download](https://github.com/emilianscheel/default-mac-app/releases/latest/download/Default-Mac-App.dmg)

<img src="./assets/screenshot-1.png" alt="Default Mac App Screenshot 1" width="100%">

<img src="./assets/screenshot-2.png" alt="Default Mac App Screenshot 2" width="100%">

## Build and Run

```sh
xcodebuild -project DefaultAppManager.xcodeproj -scheme DefaultAppManager -configuration Debug -derivedDataPath .build/DerivedData build
open ".build/DerivedData/Build/Products/Debug/Default Mac App.app"
```
