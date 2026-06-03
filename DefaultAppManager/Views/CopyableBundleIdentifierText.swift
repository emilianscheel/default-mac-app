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
            HStack(spacing: 6) {
                Text(bundleIdentifier)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(didCopy ? .green : .secondary)
                    .opacity(didCopy || isHovering ? 1 : 0)
                    .frame(width: 14)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 360, alignment: .leading)
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
