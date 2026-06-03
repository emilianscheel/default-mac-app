import AppKit
import Foundation

final class AppDiscoveryService {
    private let launchServices: LaunchServicesClient

    init(launchServices: LaunchServicesClient) {
        self.launchServices = launchServices
    }

    func discoverApps(for categories: [FileTypeCategory]) -> [InstalledApp] {
        let fileTypes = categories.flatMap(\.fileTypes)
        var handlerTypeIdentifiersByBundleID: [String: Set<String>] = [:]
        var handlerExtensionsByBundleID: [String: Set<String>] = [:]

        for fileType in fileTypes {
            for bundleIdentifier in launchServices.handlers(for: fileType) {
                handlerTypeIdentifiersByBundleID[bundleIdentifier, default: []].insert(fileType.utiIdentifier)
                handlerExtensionsByBundleID[bundleIdentifier, default: []].formUnion(fileType.extensions)
            }
        }

        let handlerBundleIDs = Set(handlerTypeIdentifiersByBundleID.keys)
        var urls = applicationURLs()

        for bundleIdentifier in handlerBundleIDs {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                urls.insert(url)
            }
        }

        var appsByBundleIdentifier: [String: InstalledApp] = [:]
        for url in urls {
            guard let app = installedApp(
                at: url,
                handlerTypeIdentifiers: handlerTypeIdentifiersByBundleID,
                handlerExtensions: handlerExtensionsByBundleID
            ) else {
                continue
            }

            let canOpenFiles = !app.supportedTypeIdentifiers.isEmpty || !app.supportedExtensions.isEmpty
            if canOpenFiles || handlerBundleIDs.contains(app.bundleIdentifier) {
                appsByBundleIdentifier[app.bundleIdentifier] = app
            }
        }

        return appsByBundleIdentifier.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func applicationURLs() -> Set<URL> {
        let roots = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        var urls: Set<URL> = []
        for root in roots {
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let url as URL in enumerator {
                guard url.pathExtension == "app" else {
                    continue
                }
                urls.insert(url)
                enumerator.skipDescendants()
            }
        }
        return urls
    }

    private func installedApp(
        at url: URL,
        handlerTypeIdentifiers: [String: Set<String>],
        handlerExtensions: [String: Set<String>]
    ) -> InstalledApp? {
        guard let bundle = Bundle(url: url),
              let bundleIdentifier = bundle.bundleIdentifier else {
            return nil
        }

        let info = bundle.infoDictionary ?? [:]
        let name = bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String
            ?? bundle.localizedInfoDictionary?["CFBundleName"] as? String
            ?? info["CFBundleDisplayName"] as? String
            ?? info["CFBundleName"] as? String
            ?? url.deletingPathExtension().lastPathComponent

        let documentTypes = info["CFBundleDocumentTypes"] as? [[String: Any]] ?? []
        var typeIdentifiers: Set<String> = []
        var extensions: Set<String> = []
        var keywords: Set<String> = [name, bundleIdentifier, url.lastPathComponent]

        for documentType in documentTypes {
            if let typeName = documentType["CFBundleTypeName"] as? String {
                keywords.insert(typeName)
            }
            if let role = documentType["CFBundleTypeRole"] as? String {
                keywords.insert(role)
            }
            if let types = documentType["LSItemContentTypes"] as? [String] {
                typeIdentifiers.formUnion(types)
                keywords.formUnion(types)
            }
            if let extValues = documentType["CFBundleTypeExtensions"] as? [String] {
                extensions.formUnion(extValues.map { $0.lowercased() })
                keywords.formUnion(extValues)
            }
        }

        let launchServicesTypeIdentifiers = handlerTypeIdentifiers[bundleIdentifier] ?? []
        let launchServicesExtensions = handlerExtensions[bundleIdentifier] ?? []
        typeIdentifiers.formUnion(launchServicesTypeIdentifiers)
        extensions.formUnion(launchServicesExtensions)
        keywords.formUnion(launchServicesTypeIdentifiers)
        keywords.formUnion(launchServicesExtensions)

        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 32, height: 32)

        return InstalledApp(
            id: bundleIdentifier,
            name: name,
            bundleIdentifier: bundleIdentifier,
            url: url,
            icon: icon,
            supportedTypeIdentifiers: typeIdentifiers,
            supportedExtensions: extensions,
            keywords: Array(keywords)
        )
    }
}
