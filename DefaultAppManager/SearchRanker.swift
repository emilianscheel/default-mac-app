import Foundation

struct SearchQuery {
    let rawValue: String
    let terms: [String]

    var isEmpty: Bool {
        rawValue.isEmpty
    }

    init(_ query: String) {
        rawValue = Self.normalize(query)
        terms = rawValue
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
    }

    static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }
}

struct SearchField {
    let text: String
    let weight: Double

    init(_ text: String, weight: Double) {
        self.text = SearchQuery.normalize(text)
        self.weight = weight
    }
}

struct SearchCandidate<T> {
    let item: T
    let fields: [SearchField]
    let originalIndex: Int
    let sortKey: String
}

struct RankedResult<T> {
    let item: T
    let score: Double
    let matchCount: Int
    let originalIndex: Int
    let sortKey: String
}

enum SearchRanker {
    static func rank<T>(_ candidates: [SearchCandidate<T>], query: SearchQuery) -> [RankedResult<T>] {
        guard !query.isEmpty else {
            return candidates.map {
                RankedResult(
                    item: $0.item,
                    score: 0,
                    matchCount: 0,
                    originalIndex: $0.originalIndex,
                    sortKey: SearchQuery.normalize($0.sortKey)
                )
            }
        }

        return candidates
            .compactMap { candidate -> RankedResult<T>? in
                guard let match = score(candidate.fields, query: query) else {
                    return nil
                }

                return RankedResult(
                    item: candidate.item,
                    score: match.score,
                    matchCount: match.matchCount,
                    originalIndex: candidate.originalIndex,
                    sortKey: SearchQuery.normalize(candidate.sortKey)
                )
            }
            .sorted(by: rankedSort)
    }

    static func score(_ fields: [SearchField], query: SearchQuery) -> (score: Double, matchCount: Int)? {
        let phraseScore = fields.map { fieldScore(field: $0, term: query.rawValue) }.max() ?? 0
        var totalScore = phraseScore
        var matchedTerms = 0

        for term in query.terms {
            let termScore = fields.map { fieldScore(field: $0, term: term) }.max() ?? 0
            if termScore > 0 {
                matchedTerms += 1
                totalScore += termScore
            } else if phraseScore == 0 {
                return nil
            }
        }

        guard totalScore > 0 else {
            return nil
        }

        return (totalScore, max(matchedTerms, phraseScore > 0 ? 1 : 0))
    }

    private static func rankedSort<T>(_ lhs: RankedResult<T>, _ rhs: RankedResult<T>) -> Bool {
        if lhs.score != rhs.score {
            return lhs.score > rhs.score
        }
        if lhs.matchCount != rhs.matchCount {
            return lhs.matchCount > rhs.matchCount
        }
        if lhs.sortKey != rhs.sortKey {
            return lhs.sortKey.localizedCaseInsensitiveCompare(rhs.sortKey) == .orderedAscending
        }
        return lhs.originalIndex < rhs.originalIndex
    }

    private static func fieldScore(field: SearchField, term: String) -> Double {
        guard !term.isEmpty, !field.text.isEmpty else {
            return 0
        }

        if field.text == term {
            return field.weight * 100
        }

        if field.text.hasPrefix(term) {
            return field.weight * 75
        }

        if field.text.contains(term) {
            return field.weight * (containsAtTokenBoundary(field.text, term: term) ? 50 : 25)
        }

        return 0
    }

    private static func containsAtTokenBoundary(_ text: String, term: String) -> Bool {
        var searchStart = text.startIndex
        while searchStart < text.endIndex,
              let range = text[searchStart...].range(of: term) {
            if range.lowerBound == text.startIndex || isBoundary(text[text.index(before: range.lowerBound)]) {
                return true
            }
            searchStart = range.upperBound
        }
        return false
    }

    private static func isBoundary(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { !CharacterSet.alphanumerics.contains($0) }
    }
}

struct SearchSnapshot {
    let query: String
    let revision: Int
    let settingsMatchesSearch: Bool
    let categoryResults: [SidebarCategoryResult]
    let appResults: [SidebarAppResult]
    let categoryDisplayFileTypes: [String: [FileType]]
    let appDisplayFileTypes: [String: [FileType]]
}

struct SearchEngine {
    let categories: [FileTypeCategory]
    let apps: [InstalledApp]
    let currentHandlers: [String: String]
    let settingsSearchText: String
    let revision: Int

    func snapshot(for rawQuery: String) -> SearchSnapshot {
        let query = SearchQuery(rawQuery)

        guard !query.isEmpty else {
            return emptySearchSnapshot(query: query.rawValue)
        }

        let assignedFileTypesByApp = Dictionary(uniqueKeysWithValues: apps.map {
            ($0.bundleIdentifier, assignedFileTypes(for: $0))
        })
        let rankedApps = rankApps(query: query, assignedFileTypesByApp: assignedFileTypesByApp)
        let rankedAppsByBundleIdentifier = Dictionary(uniqueKeysWithValues: rankedApps.map {
            ($0.app.bundleIdentifier, $0)
        })
        let rankedCategories = rankCategories(query: query, rankedApps: rankedApps)

        let categoryResults = rankedCategories.map {
            SidebarCategoryResult(category: $0.category, resultCount: $0.resultCount)
        }
        let categoryDisplayFileTypes = Dictionary(uniqueKeysWithValues: rankedCategories.map {
            ($0.category.id, $0.displayFileTypes)
        })

        let appResults = rankedApps.map {
            SidebarAppResult(app: $0.app, resultCount: $0.resultCount)
        }
        let appDisplayFileTypes = Dictionary(uniqueKeysWithValues: apps.map { app in
            let rankedApp = rankedAppsByBundleIdentifier[app.bundleIdentifier]
            let assignedFileTypes = assignedFileTypesByApp[app.bundleIdentifier] ?? []
            return (app.bundleIdentifier, rankedApp?.displayFileTypes ?? assignedFileTypes)
        })

        return SearchSnapshot(
            query: query.rawValue,
            revision: revision,
            settingsMatchesSearch: SearchRanker.score(settingsFields, query: query) != nil,
            categoryResults: categoryResults,
            appResults: appResults,
            categoryDisplayFileTypes: categoryDisplayFileTypes,
            appDisplayFileTypes: appDisplayFileTypes
        )
    }

    private var settingsFields: [SearchField] {
        [SearchField(settingsSearchText, weight: 2)]
    }

    private func emptySearchSnapshot(query: String) -> SearchSnapshot {
        let categoryDisplayFileTypes = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.fileTypes) })
        let appDisplayFileTypes = Dictionary(uniqueKeysWithValues: apps.map { ($0.bundleIdentifier, assignedFileTypes(for: $0)) })

        return SearchSnapshot(
            query: query,
            revision: revision,
            settingsMatchesSearch: true,
            categoryResults: categories.map { SidebarCategoryResult(category: $0, resultCount: $0.fileTypes.count) },
            appResults: apps.map { SidebarAppResult(app: $0, resultCount: assignedFileTypes(for: $0).count) },
            categoryDisplayFileTypes: categoryDisplayFileTypes,
            appDisplayFileTypes: appDisplayFileTypes
        )
    }

    private func rankCategories(query: SearchQuery, rankedApps: [RankedAppSearchResult]) -> [RankedCategorySearchResult] {
        let rankedAppsByBundleIdentifier = Dictionary(uniqueKeysWithValues: rankedApps.map {
            ($0.app.bundleIdentifier, $0)
        })

        return categories.enumerated().compactMap { categoryIndex, category in
            let rankedFileTypes = rankFileTypes(category.fileTypes, query: query)
            let directScore = SearchRanker.score(categoryFields(for: category), query: query)?.score ?? 0
            let supportedAppScore = supportedAppMatchScore(for: category, rankedAppsByBundleIdentifier: rankedAppsByBundleIdentifier)
            let childScore = rankedFileTypes.prefix(3).map(\.score).reduce(0, +) * 0.35
            let score = directScore + min(childScore, 180) + min(supportedAppScore, 80)

            guard score > 0 else {
                return nil
            }

            return RankedCategorySearchResult(
                category: category,
                score: score,
                originalIndex: categoryIndex,
                displayFileTypes: rankedFileTypes.isEmpty ? category.fileTypes : rankedFileTypes.map(\.item),
                resultCount: rankedFileTypes.isEmpty ? 1 : rankedFileTypes.count
            )
        }
        .sorted {
            if $0.score != $1.score {
                return $0.score > $1.score
            }
            return $0.originalIndex < $1.originalIndex
        }
    }

    private func rankApps(
        query: SearchQuery,
        assignedFileTypesByApp: [String: [FileType]]
    ) -> [RankedAppSearchResult] {
        apps.enumerated().compactMap { appIndex, app in
            let rankedFileTypes = rankFileTypes(assignedFileTypesByApp[app.bundleIdentifier] ?? [], query: query)
            let directScore = SearchRanker.score(appFields(for: app), query: query)?.score ?? 0
            let childScore = rankedFileTypes.prefix(3).map(\.score).reduce(0, +) * 0.30
            let score = directScore + min(childScore, 140)

            guard score > 0 else {
                return nil
            }

            return RankedAppSearchResult(
                app: app,
                score: score,
                originalIndex: appIndex,
                displayFileTypes: rankedFileTypes.isEmpty ? (assignedFileTypesByApp[app.bundleIdentifier] ?? []) : rankedFileTypes.map(\.item),
                resultCount: rankedFileTypes.isEmpty ? 1 : rankedFileTypes.count
            )
        }
        .sorted {
            if $0.score != $1.score {
                return $0.score > $1.score
            }
            let nameComparison = $0.app.name.localizedCaseInsensitiveCompare($1.app.name)
            if nameComparison != .orderedSame {
                return nameComparison == .orderedAscending
            }
            return $0.originalIndex < $1.originalIndex
        }
    }

    private func rankFileTypes(_ fileTypes: [FileType], query: SearchQuery) -> [RankedResult<FileType>] {
        let candidates = fileTypes.enumerated().map { index, fileType in
            SearchCandidate(
                item: fileType,
                fields: fileTypeFields(for: fileType),
                originalIndex: index,
                sortKey: fileType.displayName
            )
        }
        return SearchRanker.rank(candidates, query: query)
    }

    private func assignedFileTypes(for app: InstalledApp) -> [FileType] {
        categories.flatMap(\.fileTypes).filter { currentHandlers[$0.id] == app.bundleIdentifier }
    }

    private func supportedAppMatchScore(
        for category: FileTypeCategory,
        rankedAppsByBundleIdentifier: [String: RankedAppSearchResult]
    ) -> Double {
        let categoryExtensions = Set(category.fileTypes.flatMap(\.extensions))
        let categoryTypeIdentifiers = Set(category.fileTypes.map(\.utiIdentifier))

        return apps.compactMap { app in
            guard let rankedApp = rankedAppsByBundleIdentifier[app.bundleIdentifier],
                  !app.supportedTypeIdentifiers.isDisjoint(with: categoryTypeIdentifiers)
                    || !app.supportedExtensions.isDisjoint(with: categoryExtensions)
            else {
                return nil
            }

            return rankedApp.score * 0.20
        }
        .max() ?? 0
    }

    private func categoryFields(for category: FileTypeCategory) -> [SearchField] {
        [SearchField(category.name, weight: 4)]
            + category.keywords.map { SearchField($0, weight: 1.5) }
    }

    private func appFields(for app: InstalledApp) -> [SearchField] {
        [
            SearchField(app.name, weight: 4),
            SearchField(app.bundleIdentifier, weight: 2),
            SearchField(app.url.lastPathComponent, weight: 1.5)
        ]
            + app.keywords.map { SearchField($0, weight: 1.2) }
            + app.supportedTypeIdentifiers.map { SearchField($0, weight: 0.7) }
            + app.supportedExtensions.map { SearchField($0, weight: 0.7) }
    }

    private func fileTypeFields(for fileType: FileType) -> [SearchField] {
        [
            SearchField(fileType.displayName, weight: 4),
            SearchField(fileType.utiIdentifier, weight: 2)
        ]
            + fileType.extensions.flatMap {
                [
                    SearchField($0, weight: 3.5),
                    SearchField(".\($0)", weight: 3.5)
                ]
            }
            + fileType.keywords.map { SearchField($0, weight: 1.4) }
    }
}

private struct RankedCategorySearchResult {
    let category: FileTypeCategory
    let score: Double
    let originalIndex: Int
    let displayFileTypes: [FileType]
    let resultCount: Int
}

private struct RankedAppSearchResult {
    let app: InstalledApp
    let score: Double
    let originalIndex: Int
    let displayFileTypes: [FileType]
    let resultCount: Int
}
