import AppKit
import Foundation
import UniformTypeIdentifiers

enum SidebarSelection: Hashable {
    case settings
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

    var searchText: String {
        searchTerms.joined(separator: " ").lowercased()
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
            keywords: ["developer", "programming", "source", "xcode", "cursor", "zed", "rust", "swift", "typescript", "makefile", "dockerfile", "gemfile"],
            fileTypes: [
                type("Rust", ["rs"], "chevron.left.forwardslash.chevron.right", ["rust", "cargo"]),
                type("Swift", ["swift"], "chevron.left.forwardslash.chevron.right", ["swift", "xcode"]),
                type("Objective-C", ["m"], "chevron.left.forwardslash.chevron.right", ["objective-c", "objc", "cocoa"]),
                type("Objective-C++", ["mm"], "chevron.left.forwardslash.chevron.right", ["objective-c++", "objc++", "cocoa"]),
                type("Metal Shading Language", ["metal"], "chevron.left.forwardslash.chevron.right", ["metal", "shader", "apple gpu"]),
                type("TypeScript", ["ts"], "chevron.left.forwardslash.chevron.right", ["typescript", "javascript"]),
                type("TypeScript React", ["tsx"], "chevron.left.forwardslash.chevron.right", ["typescript", "react"]),
                type("JavaScript", ["js"], "chevron.left.forwardslash.chevron.right", ["javascript", "node"]),
                type("JavaScript React", ["jsx"], "chevron.left.forwardslash.chevron.right", ["javascript", "react"]),
                type("Vue Component", ["vue"], "chevron.left.forwardslash.chevron.right", ["vue", "javascript", "component"]),
                type("Svelte Component", ["svelte"], "chevron.left.forwardslash.chevron.right", ["svelte", "javascript", "component"]),
                type("Astro Component", ["astro"], "chevron.left.forwardslash.chevron.right", ["astro", "javascript", "component"]),
                type("Python", ["py"], "chevron.left.forwardslash.chevron.right", ["python"]),
                type("Java", ["java"], "chevron.left.forwardslash.chevron.right", ["java"]),
                type("Kotlin", ["kt"], "chevron.left.forwardslash.chevron.right", ["kotlin"]),
                type("Scala", ["scala"], "chevron.left.forwardslash.chevron.right", ["scala", "jvm"]),
                type("Groovy", ["groovy"], "chevron.left.forwardslash.chevron.right", ["groovy", "jvm", "gradle"]),
                type("Go", ["go"], "chevron.left.forwardslash.chevron.right", ["golang"]),
                type("Ruby", ["rb"], "chevron.left.forwardslash.chevron.right", ["ruby"]),
                type("PHP", ["php"], "chevron.left.forwardslash.chevron.right", ["php"]),
                type("Dart", ["dart"], "chevron.left.forwardslash.chevron.right", ["dart", "flutter"]),
                type("C", ["c"], "chevron.left.forwardslash.chevron.right", ["c"]),
                type("C++", ["cpp", "cc", "cxx"], "chevron.left.forwardslash.chevron.right", ["cpp", "c++"]),
                type("Header", ["h", "hpp"], "chevron.left.forwardslash.chevron.right", ["header"]),
                type("C#", ["cs"], "chevron.left.forwardslash.chevron.right", ["csharp", "dotnet"]),
                type("F#", ["fs", "fsx"], "chevron.left.forwardslash.chevron.right", ["fsharp", "dotnet"]),
                type("Visual Basic", ["vb"], "chevron.left.forwardslash.chevron.right", ["visual basic", "dotnet"]),
                type("Zig", ["zig"], "chevron.left.forwardslash.chevron.right", ["zig"]),
                type("Nim", ["nim"], "chevron.left.forwardslash.chevron.right", ["nim"]),
                type("D", ["d"], "chevron.left.forwardslash.chevron.right", ["dlang"]),
                type("Assembly", ["asm", "s"], "chevron.left.forwardslash.chevron.right", ["assembly", "assembler"]),
                type("R", ["r"], "chevron.left.forwardslash.chevron.right", ["r", "statistics"]),
                type("Lua", ["lua"], "chevron.left.forwardslash.chevron.right", ["lua"]),
                type("Perl", ["pl", "pm"], "chevron.left.forwardslash.chevron.right", ["perl"]),
                type("Julia", ["jl"], "chevron.left.forwardslash.chevron.right", ["julia"]),
                type("Haskell", ["hs"], "chevron.left.forwardslash.chevron.right", ["haskell"]),
                type("Elixir", ["ex", "exs"], "chevron.left.forwardslash.chevron.right", ["elixir", "beam"]),
                type("Erlang", ["erl"], "chevron.left.forwardslash.chevron.right", ["erlang", "beam"]),
                type("Clojure", ["clj", "cljs"], "chevron.left.forwardslash.chevron.right", ["clojure", "clojurescript"]),
                type("Racket", ["rkt"], "chevron.left.forwardslash.chevron.right", ["racket", "scheme"]),
                type("JSON", ["json"], "curlybraces", ["json"]),
                type("YAML", ["yaml", "yml"], "curlybraces", ["yaml"]),
                type("TOML", ["toml"], "curlybraces", ["toml"]),
                type("XML", ["xml"], "curlybraces", ["xml", "markup"]),
                type("GraphQL", ["graphql", "gql"], "curlybraces", ["graphql", "schema"]),
                type("Markdown", ["md"], "text.alignleft", ["markdown"]),
                type("HTML", ["html", "htm"], "chevron.left.forwardslash.chevron.right", ["html"]),
                type("CSS", ["css"], "chevron.left.forwardslash.chevron.right", ["css"]),
                type("SCSS", ["scss"], "chevron.left.forwardslash.chevron.right", ["scss", "sass", "css"]),
                type("Sass", ["sass"], "chevron.left.forwardslash.chevron.right", ["sass", "scss", "css"]),
                type("Less", ["less"], "chevron.left.forwardslash.chevron.right", ["less", "css"]),
                type("SQL", ["sql"], "chevron.left.forwardslash.chevron.right", ["sql"]),
                type("CMake", ["cmake"], "chevron.left.forwardslash.chevron.right", ["cmake", "build"]),
                type("Gradle", ["gradle"], "chevron.left.forwardslash.chevron.right", ["gradle", "build", "android"]),
                type("Protocol Buffers", ["proto"], "chevron.left.forwardslash.chevron.right", ["protobuf", "grpc"]),
                type("Terraform", ["tf", "tfvars"], "chevron.left.forwardslash.chevron.right", ["terraform", "infrastructure"]),
                type("Docker Ignore", ["dockerignore"], "chevron.left.forwardslash.chevron.right", ["docker", "dockerfile", "container"]),
                type("EditorConfig", ["editorconfig"], "chevron.left.forwardslash.chevron.right", ["editorconfig", "editor"]),
                type("Xcode Storyboard", ["storyboard"], "chevron.left.forwardslash.chevron.right", ["xcode", "interface builder"]),
                type("Xcode Interface", ["xib"], "chevron.left.forwardslash.chevron.right", ["xcode", "interface builder"]),
                type("Shell Script", ["sh", "zsh", "bash"], "terminal", ["shell", "terminal"])
            ]
        ),
        FileTypeCategory(
            id: "archives",
            name: "Archives",
            systemImage: "archivebox",
            keywords: ["archive", "compressed", "zip", "tar", "rar", "7z"],
            fileTypes: [
                type("ZIP Archive", ["zip"], "archivebox", ["zip", "compressed"]),
                type("7-Zip Archive", ["7z"], "archivebox", ["7zip", "compressed"]),
                type("RAR Archive", ["rar"], "archivebox", ["rar", "compressed"]),
                type("Tape Archive", ["tar"], "archivebox", ["tar", "archive"]),
                type("Gzip Archive", ["gz"], "archivebox", ["gzip", "compressed"]),
                type("Bzip2 Archive", ["bz2"], "archivebox", ["bzip2", "compressed"]),
                type("XZ Archive", ["xz"], "archivebox", ["xz", "compressed"])
            ]
        ),
        FileTypeCategory(
            id: "disk-images-installers",
            name: "Disk Images & Installers",
            systemImage: "externaldrive",
            keywords: ["disk image", "installer", "package", "mount", "iso", "dmg"],
            fileTypes: [
                type("Apple Disk Image", ["dmg"], "externaldrive", ["disk image", "installer", "mount"]),
                type("ISO Disk Image", ["iso"], "externaldrive", ["disk image", "optical", "mount"]),
                type("Installer Package", ["pkg"], "shippingbox", ["installer", "package"]),
                type("Installer Metapackage", ["mpkg"], "shippingbox", ["installer", "package"])
            ]
        ),
        FileTypeCategory(
            id: "fonts",
            name: "Fonts",
            systemImage: "textformat",
            keywords: ["font", "typeface", "typography"],
            fileTypes: [
                type("TrueType Font", ["ttf"], "textformat", ["font", "truetype"]),
                type("OpenType Font", ["otf"], "textformat", ["font", "opentype"]),
                type("Web Open Font", ["woff"], "textformat", ["font", "web"]),
                type("Web Open Font 2", ["woff2"], "textformat", ["font", "web"])
            ]
        ),
        FileTypeCategory(
            id: "ebooks",
            name: "Ebooks",
            systemImage: "book",
            keywords: ["ebook", "book", "reader", "kindle"],
            fileTypes: [
                type("EPUB Ebook", ["epub"], "book", ["ebook", "reader"]),
                type("Mobipocket Ebook", ["mobi"], "book", ["ebook", "kindle"]),
                type("Amazon Kindle Ebook", ["azw"], "book", ["ebook", "kindle"]),
                type("Amazon Kindle Ebook 3", ["azw3"], "book", ["ebook", "kindle"])
            ]
        ),
        FileTypeCategory(
            id: "data-config",
            name: "Data & Config",
            systemImage: "gearshape.2",
            keywords: ["data", "configuration", "config", "preferences", "property list", "environment"],
            fileTypes: [
                type("Property List", ["plist"], "gearshape.2", ["plist", "preferences", "apple"]),
                type("INI Configuration", ["ini"], "gearshape.2", ["ini", "config"]),
                type("Configuration", ["conf"], "gearshape.2", ["config", "configuration"]),
                type("Environment Variables", ["env"], "gearshape.2", ["environment", "dotenv", "config"]),
                type("Lock File", ["lock"], "lock", ["lockfile", "dependencies"]),
                type("Log File", ["log"], "doc.plaintext", ["log", "logs"]),
                type("TSV", ["tsv"], "tablecells", ["tab separated", "data"])
            ]
        ),
        FileTypeCategory(
            id: "design",
            name: "Design",
            systemImage: "paintbrush",
            keywords: ["design", "graphics", "creative", "adobe", "figma", "sketch"],
            fileTypes: [
                type("Sketch Document", ["sketch"], "paintbrush", ["sketch", "design"]),
                type("Figma Document", ["fig"], "paintbrush", ["figma", "design"]),
                type("Photoshop Document", ["psd"], "paintbrush", ["photoshop", "adobe"]),
                type("Illustrator Document", ["ai"], "paintbrush", ["illustrator", "adobe"]),
                type("InDesign Document", ["indd"], "paintbrush", ["indesign", "adobe"]),
                type("Adobe XD Document", ["xd"], "paintbrush", ["adobe xd", "design"])
            ]
        ),
        FileTypeCategory(
            id: "three-d-cad",
            name: "3D & CAD",
            systemImage: "cube",
            keywords: ["3d", "cad", "model", "mesh", "blender", "autocad"],
            fileTypes: [
                type("Blender Scene", ["blend"], "cube", ["blender", "3d"]),
                type("Wavefront OBJ", ["obj"], "cube", ["wavefront", "3d", "mesh"]),
                type("FBX Model", ["fbx"], "cube", ["fbx", "3d", "model"]),
                type("STL Model", ["stl"], "cube", ["stl", "3d", "printing"]),
                type("Collada Model", ["dae"], "cube", ["collada", "3d"]),
                type("glTF Model", ["gltf"], "cube", ["gltf", "3d"]),
                type("Binary glTF Model", ["glb"], "cube", ["glb", "gltf", "3d"]),
                type("AutoCAD Drawing", ["dwg"], "cube", ["autocad", "cad"]),
                type("DXF Drawing", ["dxf"], "cube", ["autocad", "cad"])
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
