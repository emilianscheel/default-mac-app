import AppKit
import SwiftUI

@main
struct DefaultAppManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppStore()

    var body: some Scene {
        MenuBarExtra {
            Button {
                appDelegate.showSettings(store: store)
            } label: {
                Label("Open Default Mac App", systemImage: "door.left.hand.open")
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
        } label: {
            Image(systemName: "door.left.hand.open")
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func showSettings(store: AppStore) {
        if window == nil {
            let rootView = SettingsRootView()
                .environmentObject(store)

            let hostingController = NSHostingController(rootView: rootView)
            let settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow.title = "Default Mac App"
            settingsWindow.setContentSize(NSSize(width: 1020, height: 680))
            settingsWindow.minSize = NSSize(width: 820, height: 540)
            settingsWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            settingsWindow.titlebarAppearsTransparent = true
            settingsWindow.toolbarStyle = .unified
            settingsWindow.delegate = self
            settingsWindow.isReleasedWhenClosed = false
            settingsWindow.setFrameAutosaveName("DefaultAppManagerSettingsWindow")
            window = settingsWindow
        }

        store.refreshAnimated()
        NSApp.setActivationPolicy(.regular)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
