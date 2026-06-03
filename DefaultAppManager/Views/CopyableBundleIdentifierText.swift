import AppKit
import SwiftUI

struct CopyableBundleIdentifierText: View {
    let bundleIdentifier: String

    @State private var isHovering = false
    @State private var didCopy = false

    var body: some View {
        Button {
            copyBundleIdentifier()
        } label: {
            HStack(spacing: 4) {
                Text(bundleIdentifier)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .opacity(didCopy || isHovering ? 1 : 0)
                    .frame(width: 11)
                    .animation(.easeInOut(duration: 0.15), value: isHovering)
                    .animation(.easeInOut(duration: 0.15), value: didCopy)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .help("Copy bundle identifier")
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
