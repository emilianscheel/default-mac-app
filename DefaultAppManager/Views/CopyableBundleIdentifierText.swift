import AppKit
import SwiftUI

struct CopyableBundleIdentifierText: View {
    let bundleIdentifier: String
    let textStyle: Font.TextStyle

    @State private var isHovering = false
    @State private var didCopy = false

    init(bundleIdentifier: String, textStyle: Font.TextStyle = .subheadline) {
        self.bundleIdentifier = bundleIdentifier
        self.textStyle = textStyle
    }

    var body: some View {
        Button {
            copyBundleIdentifier()
        } label: {
            HStack(spacing: 4) {
                Text(bundleIdentifier)
                    .font(.system(textStyle, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

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
