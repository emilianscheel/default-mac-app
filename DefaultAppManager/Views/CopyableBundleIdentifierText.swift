import AppKit
import SwiftUI

struct CopyableBundleIdentifierText: View {
    let bundleIdentifier: String
    let textStyle: Font.TextStyle
    let searchQuery: String

    @State private var isHovering = false
    @State private var didCopy = false

    init(bundleIdentifier: String, textStyle: Font.TextStyle = .subheadline, searchQuery: String = "") {
        self.bundleIdentifier = bundleIdentifier
        self.textStyle = textStyle
        self.searchQuery = searchQuery
    }

    var body: some View {
        Button {
            copyBundleIdentifier()
        } label: {
            HStack(spacing: 4) {
                SearchHighlightedText(
                    bundleIdentifier,
                    query: searchQuery,
                    font: .system(textStyle, design: .monospaced),
                    foregroundStyle: .secondary
                )

                Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .opacity(didCopy || isHovering ? 1 : 0)
                    .frame(width: 11, height: 11)
                    .animation(.easeInOut(duration: 0.15), value: isHovering)
                    .animation(.easeInOut(duration: 0.15), value: didCopy)
            }
            .frame(height: lineHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .help("Copy bundle identifier")
    }

    private var lineHeight: CGFloat {
        switch textStyle {
        case .caption, .caption2:
            15
        case .subheadline:
            18
        default:
            18
        }
    }

    private func copyBundleIdentifier() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(bundleIdentifier, forType: .string)
        didCopy = true

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            didCopy = false
        }
    }
}

struct SearchHighlightedText: View {
    let text: String
    let query: String
    let font: Font
    let foregroundStyle: HierarchicalShapeStyle

    init(
        _ text: String,
        query: String,
        font: Font,
        foregroundStyle: HierarchicalShapeStyle = .primary
    ) {
        self.text = text
        self.query = query
        self.font = font
        self.foregroundStyle = foregroundStyle
    }

    var body: some View {
        Text(highlightedText)
            .font(font)
            .foregroundStyle(foregroundStyle)
            .lineLimit(1)
    }

    private var highlightedText: AttributedString {
        var attributed = AttributedString(text)
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return attributed
        }

        var searchStart = attributed.startIndex
        while searchStart < attributed.endIndex,
            let range = attributed[searchStart...].range(
                of: trimmedQuery,
                options: [.caseInsensitive, .diacriticInsensitive]
            )
        {
            attributed[range].backgroundColor = Color(nsColor: .separatorColor).opacity(0.65)
            searchStart = range.upperBound
        }

        return attributed
    }
}
