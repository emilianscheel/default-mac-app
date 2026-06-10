import Foundation
import SwiftUI

struct SidebarCategoryResult: Identifiable {
    let category: FileTypeCategory
    let resultCount: Int

    var id: String {
        category.id
    }
}

struct SidebarAppResult: Identifiable {
    let app: InstalledApp
    let resultCount: Int

    var id: String {
        app.bundleIdentifier
    }
}

@MainActor
final class AppStore: ObservableObject {
    @Published var categories = FileTypeCatalog.categories {
        didSet {
            invalidateSearchCache()
        }
    }
    @Published var apps: [InstalledApp] = [] {
        didSet {
            invalidateSearchCache()
        }
    }
    @Published var currentHandlers: [String: String] = [:] {
        didSet {
            invalidateSearchCache()
        }
    }
    @Published var selection: SidebarSelection?
    @Published var searchText = "" {
        didSet {
            selectTopSidebarSearchResultIfNeeded()
        }
    }
    @Published var errorMessage: String?
    @Published var selectedAppFileTypeID: String?
    @Published var showInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showInMenuBar, forKey: Self.showInMenuBarKey)
        }
    }
    @Published var openOnLogin: Bool {
        didSet {
            UserDefaults.standard.set(openOnLogin, forKey: Self.openOnLoginKey)
        }
    }

    private static let showInMenuBarKey = "ShowInMenuBar"
    private static let openOnLoginKey = "OpenOnLogin"
    private let launchServices = LaunchServicesClient()
    private lazy var discovery = AppDiscoveryService(launchServices: launchServices)
    private let previousDefaultsKey = "PreviousDefaultHandlers"
    private var refreshTask: Task<Void, Never>?
    private var searchRevision = 0
    private var cachedSearchSnapshot: SearchSnapshot?
    private var previousDefaults: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: previousDefaultsKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: previousDefaultsKey) }
    }

    init() {
        showInMenuBar = Self.boolPreference(forKey: Self.showInMenuBarKey, defaultValue: true)
        openOnLogin = Self.boolPreference(forKey: Self.openOnLoginKey, defaultValue: true)
        refresh()
        selection = .category(categories[0].id)
    }

    func setShowInMenuBar(_ isShown: Bool) {
        showInMenuBar = isShown
    }

    func setOpenOnLogin(_ isEnabled: Bool) {
        openOnLogin = isEnabled
    }

    func refresh() {
        categories = FileTypeCatalog.categories
        apps = discovery.discoverApps(for: categories)
        refreshHandlers()
        reconcileSelection()
    }

    func refreshAnimated() {
        refreshTask?.cancel()

        let discovery = discovery
        let categories = FileTypeCatalog.categories
        refreshTask = Task {
            let discoveredApps = await Task.detached(priority: .userInitiated) {
                discovery.discoverApps(for: categories)
            }.value

            guard !Task.isCancelled else {
                return
            }

            withAnimation(.snappy(duration: 0.22)) {
                self.categories = categories
                self.apps = discoveredApps
            }
            refreshHandlers()
            reconcileSelection()
        }
    }

    func refreshHandlers() {
        var handlers: [String: String] = [:]
        for fileType in allFileTypes {
            if let bundleIdentifier = launchServices.defaultHandler(for: fileType) {
                handlers[fileType.id] = bundleIdentifier
            }
        }
        currentHandlers = handlers
    }

    var allFileTypes: [FileType] {
        categories.flatMap(\.fileTypes)
    }

    var sidebarSearchQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var detailSearchQuery: String {
        sidebarSearchQuery
    }

    var hasNoSidebarSearchResults: Bool {
        let snapshot = searchSnapshot
        return !snapshot.query.isEmpty && !snapshot.settingsMatchesSearch && snapshot.categoryResults.isEmpty && snapshot.appResults.isEmpty
    }

    var shouldShowSettingsInSidebar: Bool {
        searchSnapshot.query.isEmpty || searchSnapshot.settingsMatchesSearch
    }

    var sidebarCategoryResults: [SidebarCategoryResult] {
        searchSnapshot.categoryResults
    }

    var sidebarAppResults: [SidebarAppResult] {
        searchSnapshot.appResults
    }

    var filteredCategories: [FileTypeCategory] {
        sidebarCategoryResults.map(\.category)
    }

    var filteredApps: [InstalledApp] {
        sidebarAppResults.map(\.app)
    }

    func category(for id: String) -> FileTypeCategory? {
        categories.first { $0.id == id }
    }

    func app(for bundleIdentifier: String) -> InstalledApp? {
        apps.first { $0.bundleIdentifier == bundleIdentifier }
    }

    func currentAppName(for fileType: FileType) -> String {
        guard let bundleIdentifier = currentHandlers[fileType.id] else {
            return "No Default"
        }
        return app(for: bundleIdentifier)?.name ?? bundleIdentifier
    }

    func appOptions(for fileType: FileType) -> [InstalledApp] {
        let handlerIDs = launchServices.handlers(for: fileType)
        let ranked = handlerIDs.compactMap { app(for: $0) }

        if !ranked.isEmpty {
            return ranked.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        let byDeclaredSupport = apps.filter { app in
            !app.supportedTypeIdentifiers.isDisjoint(with: [fileType.utiIdentifier])
                || !app.supportedExtensions.isDisjoint(with: Set(fileType.extensions))
        }

        return byDeclaredSupport.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func setDefault(app: InstalledApp, for fileType: FileType) {
        do {
            let current = currentHandlers[fileType.id] ?? launchServices.defaultHandler(for: fileType)
            if current != app.bundleIdentifier {
                var history = previousDefaults
                if history[fileType.id] == nil, let current {
                    history[fileType.id] = current
                }
                previousDefaults = history
            }

            try launchServices.setDefaultHandler(app.bundleIdentifier, for: fileType)
            currentHandlers[fileType.id] = app.bundleIdentifier
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setDefault(app: InstalledApp, for category: FileTypeCategory) {
        for fileType in category.fileTypes {
            setDefault(app: app, for: fileType)
        }
    }

    func assignedFileTypes(for app: InstalledApp) -> [FileType] {
        allFileTypes.filter { currentHandlers[$0.id] == app.bundleIdentifier }
    }

    func filteredFileTypes(in category: FileTypeCategory) -> [FileType] {
        searchSnapshot.categoryDisplayFileTypes[category.id] ?? category.fileTypes
    }

    func filteredAssignedFileTypes(for app: InstalledApp) -> [FileType] {
        searchSnapshot.appDisplayFileTypes[app.bundleIdentifier] ?? assignedFileTypes(for: app)
    }

    func sidebarResultCount(for category: FileTypeCategory) -> Int {
        sidebarCategoryResults.first { $0.category.id == category.id }?.resultCount ?? 0
    }

    func sidebarResultCount(for app: InstalledApp) -> Int {
        sidebarAppResults.first { $0.app.bundleIdentifier == app.bundleIdentifier }?.resultCount ?? 0
    }

    func canRestorePreviousDefault(for fileType: FileType) -> Bool {
        previousDefaults[fileType.id] != nil
    }

    func restorePreviousDefault(for fileType: FileType) {
        guard let previousBundleIdentifier = previousDefaults[fileType.id] else {
            return
        }

        do {
            try launchServices.setDefaultHandler(previousBundleIdentifier, for: fileType)
            currentHandlers[fileType.id] = previousBundleIdentifier
            var history = previousDefaults
            history.removeValue(forKey: fileType.id)
            previousDefaults = history
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var normalizedSearch: String {
        SearchQuery.normalize(searchText)
    }

    private var searchSnapshot: SearchSnapshot {
        let query = normalizedSearch
        if let cachedSearchSnapshot,
           cachedSearchSnapshot.query == query,
           cachedSearchSnapshot.revision == searchRevision {
            return cachedSearchSnapshot
        }

        let snapshot = makeSearchSnapshot(query: query)
        cachedSearchSnapshot = snapshot
        return snapshot
    }

    private func makeSearchSnapshot(query: String) -> SearchSnapshot {
        SearchEngine(
            categories: categories,
            apps: apps,
            currentHandlers: currentHandlers,
            settingsSearchText: settingsSearchText,
            revision: searchRevision
        )
        .snapshot(for: query)
    }

    private var settingsSearchText: String {
        let settingsSearchText = [
            "settings",
            "preferences",
            "menu bar",
            "login",
            "open on login",
            "gear"
        ].joined(separator: " ")

        return settingsSearchText
    }

    private static func boolPreference(forKey key: String, defaultValue: Bool) -> Bool {
        guard UserDefaults.standard.object(forKey: key) != nil else {
            return defaultValue
        }
        return UserDefaults.standard.bool(forKey: key)
    }

    private func invalidateSearchCache() {
        searchRevision += 1
        cachedSearchSnapshot = nil
    }

    private func reconcileSelection() {
        if selectTopSidebarSearchResultIfNeeded() {
            return
        }

        switch selection {
        case .settings:
            break
        case .app(let bundleIdentifier):
            if app(for: bundleIdentifier) == nil {
                selection = .category(categories[0].id)
                selectedAppFileTypeID = nil
            }
        case .category(let id):
            if category(for: id) == nil {
                selection = .category(categories[0].id)
            }
        case nil:
            selection = .category(categories[0].id)
        }
    }

    @discardableResult
    private func selectTopSidebarSearchResultIfNeeded() -> Bool {
        guard !sidebarSearchQuery.isEmpty else {
            return false
        }

        if shouldShowSettingsInSidebar {
            updateSelectionIfNeeded(.settings)
        } else if let category = filteredCategories.first {
            updateSelectionIfNeeded(.category(category.id))
        } else if let app = filteredApps.first {
            updateSelectionIfNeeded(.app(app.bundleIdentifier))
        } else {
            updateSelectionIfNeeded(nil)
        }

        return true
    }

    private func updateSelectionIfNeeded(_ newSelection: SidebarSelection?) {
        guard selection != newSelection else {
            return
        }
        selection = newSelection
    }
}
