import AppKit
import Foundation
import UniformTypeIdentifiers

enum SidebarSelection: Hashable {
    case category(String)
    case app(String)
}

struct FileTypeCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let systemImage: String
    let keywords: [String]
    let fileTypes: [FileType]

    var searchText: String {
        ([name] + keywords + fileTypes.flatMap(\.searchTerms)).joined(separator: " ").lowercased()
    }
}

struct FileType: Identifiable, Hashable {
    let id: String
    let displayName: String
    let extensions: [String]
    let utiIdentifier: String
    let systemImage: String
    let keywords: [String]

    var primaryExtension: String {
        extensions.first.map { ".\($0)" } ?? utiIdentifier
    }

    var searchTerms: [String] {
        [displayName, utiIdentifier] + extensions + extensions.map { ".\($0)" } + keywords
    }
}

struct InstalledApp: Identifiable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let url: URL
    let icon: NSImage
    let supportedTypeIdentifiers: Set<String>
    let supportedExtensions: Set<String>
    let keywords: [String]

    var searchText: String {
        ([name, bundleIdentifier, url.lastPathComponent] + keywords + Array(supportedTypeIdentifiers) + Array(supportedExtensions))
            .joined(separator: " ")
            .lowercased()
    }
}

extension InstalledApp: Equatable {
    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier
    }
}

extension InstalledApp: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
    }
}

enum FileTypeCatalog {
    static let categories: [FileTypeCategory] = [
        FileTypeCategory(
            id: "documents",
            name: "Documents",
            systemImage: "doc.text",
            keywords: ["word", "pages", "pdf", "rtf", "text", "writer", "microsoft word"],
            fileTypes: [
                type("Word Document", ["docx"], "doc.richtext", ["word", "microsoft word", "office"]),
                type("Word 97-2004 Document", ["doc"], "doc.richtext", ["word", "microsoft word", "office"]),
                type("Pages Document", ["pages"], "doc.richtext", ["pages", "apple pages"]),
                type("PDF", ["pdf"], "doc.richtext", ["acrobat", "preview"]),
                type("Rich Text", ["rtf"], "doc.richtext", ["textedit", "rtf"]),
                type("Plain Text", ["txt"], "doc.plaintext", ["text", "notes"]),
                type("OpenDocument Text", ["odt"], "doc.richtext", ["libreoffice", "writer"])
            ]
        ),
        FileTypeCategory(
            id: "spreadsheets",
            name: "Spreadsheets",
            systemImage: "tablecells",
            keywords: ["excel", "numbers", "csv", "sheets", "microsoft excel"],
            fileTypes: [
                type("CSV", ["csv"], "tablecells", ["comma separated", "numbers", "excel"]),
                type("Excel Workbook", ["xlsx"], "tablecells", ["excel", "microsoft excel", "office"]),
                type("Excel 97-2004 Workbook", ["xls"], "tablecells", ["excel", "microsoft excel", "office"]),
                type("Numbers Spreadsheet", ["numbers"], "tablecells", ["numbers", "apple numbers"]),
                type("OpenDocument Spreadsheet", ["ods"], "tablecells", ["libreoffice", "calc"])
            ]
        ),
        FileTypeCategory(
            id: "presentations",
            name: "Presentations",
            systemImage: "rectangle.on.rectangle",
            keywords: ["powerpoint", "keynote", "slides", "microsoft powerpoint"],
            fileTypes: [
                type("PowerPoint Presentation", ["pptx"], "rectangle.on.rectangle", ["powerpoint", "microsoft powerpoint", "office"]),
                type("PowerPoint 97-2004 Presentation", ["ppt"], "rectangle.on.rectangle", ["powerpoint", "microsoft powerpoint", "office"]),
                type("Keynote Presentation", ["key"], "rectangle.on.rectangle", ["keynote", "apple keynote"]),
                type("OpenDocument Presentation", ["odp"], "rectangle.on.rectangle", ["libreoffice", "impress"])
            ]
        ),
        FileTypeCategory(
            id: "code",
            name: "Code",
            systemImage: "chevron.left.forwardslash.chevron.right",
            keywords: ["developer", "programming", "source", "xcode", "cursor", "zed", "rust", "swift", "typescript"],
            fileTypes: [
                type("Rust", ["rs"], "chevron.left.forwardslash.chevron.right", ["rust", "cargo"]),
                type("Swift", ["swift"], "chevron.left.forwardslash.chevron.right", ["swift", "xcode"]),
                type("TypeScript", ["ts"], "chevron.left.forwardslash.chevron.right", ["typescript", "javascript"]),
                type("TypeScript React", ["tsx"], "chevron.left.forwardslash.chevron.right", ["typescript", "react"]),
                type("JavaScript", ["js"], "chevron.left.forwardslash.chevron.right", ["javascript", "node"]),
                type("JavaScript React", ["jsx"], "chevron.left.forwardslash.chevron.right", ["javascript", "react"]),
                type("Python", ["py"], "chevron.left.forwardslash.chevron.right", ["python"]),
                type("Java", ["java"], "chevron.left.forwardslash.chevron.right", ["java"]),
                type("Kotlin", ["kt"], "chevron.left.forwardslash.chevron.right", ["kotlin"]),
                type("Go", ["go"], "chevron.left.forwardslash.chevron.right", ["golang"]),
                type("Ruby", ["rb"], "chevron.left.forwardslash.chevron.right", ["ruby"]),
                type("PHP", ["php"], "chevron.left.forwardslash.chevron.right", ["php"]),
                type("C", ["c"], "chevron.left.forwardslash.chevron.right", ["c"]),
                type("C++", ["cpp", "cc", "cxx"], "chevron.left.forwardslash.chevron.right", ["cpp", "c++"]),
                type("Header", ["h", "hpp"], "chevron.left.forwardslash.chevron.right", ["header"]),
                type("C#", ["cs"], "chevron.left.forwardslash.chevron.right", ["csharp", "dotnet"]),
                type("JSON", ["json"], "curlybraces", ["json"]),
                type("YAML", ["yaml", "yml"], "curlybraces", ["yaml"]),
                type("TOML", ["toml"], "curlybraces", ["toml"]),
                type("Markdown", ["md"], "text.alignleft", ["markdown"]),
                type("HTML", ["html", "htm"], "chevron.left.forwardslash.chevron.right", ["html"]),
                type("CSS", ["css"], "chevron.left.forwardslash.chevron.right", ["css"]),
                type("SQL", ["sql"], "chevron.left.forwardslash.chevron.right", ["sql"]),
                type("Shell Script", ["sh", "zsh", "bash"], "terminal", ["shell", "terminal"])
            ]
        ),
        FileTypeCategory(
            id: "images",
            name: "Images",
            systemImage: "photo",
            keywords: ["picture", "photo", "preview", "graphics"],
            fileTypes: [
                type("PNG", ["png"], "photo", ["image"]),
                type("JPEG", ["jpg", "jpeg"], "photo", ["image"]),
                type("HEIC", ["heic"], "photo", ["image", "iphone"]),
                type("GIF", ["gif"], "photo", ["image", "animated"]),
                type("TIFF", ["tiff", "tif"], "photo", ["image"]),
                type("SVG", ["svg"], "photo", ["vector"]),
                type("WebP", ["webp"], "photo", ["image"])
            ]
        ),
        FileTypeCategory(
            id: "videos",
            name: "Videos",
            systemImage: "film",
            keywords: ["movie", "quicktime", "media"],
            fileTypes: [
                type("QuickTime Movie", ["mov"], "film", ["quicktime", "movie"]),
                type("MPEG-4 Video", ["mp4"], "film", ["video", "movie"]),
                type("M4V Video", ["m4v"], "film", ["video", "movie"]),
                type("AVI Video", ["avi"], "film", ["video", "movie"]),
                type("Matroska Video", ["mkv"], "film", ["video", "movie"]),
                type("WebM Video", ["webm"], "film", ["video", "movie"])
            ]
        ),
        FileTypeCategory(
            id: "audio",
            name: "Audio",
            systemImage: "waveform",
            keywords: ["music", "sound", "media"],
            fileTypes: [
                type("MP3", ["mp3"], "waveform", ["audio", "music"]),
                type("M4A", ["m4a"], "waveform", ["audio", "music"]),
                type("WAV", ["wav"], "waveform", ["audio", "music"]),
                type("AIFF", ["aiff", "aif"], "waveform", ["audio", "music"]),
                type("FLAC", ["flac"], "waveform", ["audio", "music"]),
                type("AAC", ["aac"], "waveform", ["audio", "music"])
            ]
        )
    ]

    static func fileType(for id: String) -> FileType? {
        categories.flatMap(\.fileTypes).first { $0.id == id }
    }

    private static func type(_ displayName: String, _ extensions: [String], _ systemImage: String, _ keywords: [String]) -> FileType {
        let preferredExtension = extensions[0]
        let identifier = UTType(filenameExtension: preferredExtension)?.identifier ?? "dyn.default-app-manager.\(preferredExtension)"
        return FileType(
            id: "\(identifier)-\(preferredExtension)",
            displayName: displayName,
            extensions: extensions,
            utiIdentifier: identifier,
            systemImage: systemImage,
            keywords: keywords
        )
    }
}
