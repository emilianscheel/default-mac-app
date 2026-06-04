import AppKit
import SwiftUI

@main
struct DefaultAppManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let store = AppStore()
    private var statusItem: NSStatusItem?
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc private func openSettings() {
        showSettings()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "door.left.hand.open", accessibilityDescription: "Open Default Mac App")
            button.image?.isTemplate = true
            button.action = #selector(openSettings)
            button.target = self
        }
        statusItem = item
    }

    private func showSettings() {
        if window == nil {
            let rootView = SettingsRootView()
                .environmentObject(store)

            let hostingController = NSHostingController(rootView: rootView)
            let settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow.title = ""
            settingsWindow.titleVisibility = .hidden
            settingsWindow.setContentSize(NSSize(width: 1020, height: 680))
            settingsWindow.minSize = NSSize(width: 820, height: 540)
            settingsWindow.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            settingsWindow.titlebarAppearsTransparent = true
            settingsWindow.toolbar = makeSettingsToolbar()
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

    private func makeSettingsToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "SettingsWindowToolbar")
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.displayMode = .iconOnly
        toolbar.sizeMode = .regular
        toolbar.showsBaselineSeparator = false
        return toolbar
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
