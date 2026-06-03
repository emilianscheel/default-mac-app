import Foundation

final class AppStore: ObservableObject {
    @Published var categories = FileTypeCatalog.categories
    @Published var apps: [InstalledApp] = []
    @Published var currentHandlers: [String: String] = [:]
    @Published var selection: SidebarSelection?
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published var selectedAppFileTypeID: String?

    private let launchServices = LaunchServicesClient()
    private lazy var discovery = AppDiscoveryService(launchServices: launchServices)
    private let previousDefaultsKey = "PreviousDefaultHandlers"
    private var previousDefaults: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: previousDefaultsKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: previousDefaultsKey) }
    }

    init() {
        refresh()
        selection = .category(categories[0].id)
    }

    func refresh() {
        categories = FileTypeCatalog.categories
        apps = discovery.discoverApps(for: categories)
        refreshHandlers()
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

    var filteredCategories: [FileTypeCategory] {
        let query = normalizedSearch
        guard !query.isEmpty else {
            return categories
        }
        return categories.filter { $0.searchText.contains(query) || appSearchMatchesCategory($0, query: query) }
    }

    var filteredApps: [InstalledApp] {
        let query = normalizedSearch
        guard !query.isEmpty else {
            return apps
        }
        return apps.filter { $0.searchText.contains(query) }
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
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func appSearchMatchesCategory(_ category: FileTypeCategory, query: String) -> Bool {
        return apps.contains { app in
            app.searchText.contains(query) && category.fileTypes.contains { fileType in
                app.supportedTypeIdentifiers.contains(fileType.utiIdentifier)
                    || !app.supportedExtensions.isDisjoint(with: Set(fileType.extensions))
            }
        }
    }
}
