import AppKit
import SwiftUI

struct CategoryDetailView: View {
    @EnvironmentObject private var store: AppStore
    let category: FileTypeCategory

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 18)

            Divider()

            List(category.fileTypes) { fileType in
                FileTypeAssignmentRow(fileType: fileType)
                    .padding(.vertical, 6)
                    .padding(.leading, 12)
                    .padding(.trailing, 12)
            }
            .listStyle(.inset)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(category.name)
                    .font(.title2.weight(.semibold))
                Text("\(category.fileTypes.count) file types")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            AppChoiceMenu(
                title: "Set All",
                options: store.apps,
                emptyTitle: "No registered apps",
                isSelected: { app in
                    category.fileTypes.allSatisfy { fileType in
                        store.currentHandlers[fileType.id] == app.bundleIdentifier
                    }
                },
                select: { app in
                    store.setDefault(app: app, for: category)
                }
            )
            .frame(minWidth: 190, idealWidth: 220, maxWidth: 260, alignment: .trailing)
            .frame(height: 22)
            .fixedSize(horizontal: true, vertical: false)
            .help("Set the default opening app for every file type in \(category.name)")
        }
    }
}

struct FileTypeAssignmentRow: View {
    @EnvironmentObject private var store: AppStore
    let fileType: FileType

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(fileType.displayName)
                    .font(.body)
                HStack(spacing: 8) {
                    Text(fileType.primaryExtension)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                    CopyableBundleIdentifierText(
                        bundleIdentifier: fileType.utiIdentifier, textStyle: .caption)
                }
            }

            Spacer(minLength: 20)

            AppPickerMenu(fileType: fileType)
        }
    }
}

struct AppPickerMenu: View {
    @EnvironmentObject private var store: AppStore
    let fileType: FileType

    var body: some View {
        AppChoiceMenu(
            title: store.currentAppName(for: fileType),
            options: store.appOptions(for: fileType),
            emptyTitle: "No registered apps",
            isSelected: { app in
                store.currentHandlers[fileType.id] == app.bundleIdentifier
            },
            select: { app in
                store.setDefault(app: app, for: fileType)
            }
        )
        .frame(minWidth: 190, idealWidth: 220, maxWidth: 260, alignment: .trailing)
        .frame(height: 22)
        .fixedSize(horizontal: true, vertical: false)
        .help("Choose the default app for \(fileType.displayName)")
    }
}

struct AppChoiceMenu: View {
    let title: String
    let options: [InstalledApp]
    let emptyTitle: String
    let isSelected: (InstalledApp) -> Bool
    let select: (InstalledApp) -> Void

    @State private var isHovered = false

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            AppChoiceMenuButton(
                title: title,
                options: options,
                emptyTitle: emptyTitle,
                isSelected: isSelected,
                select: select
            )
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background {
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovered ? Color(nsColor: .labelColor).opacity(0.07) : .clear)
            }
            .contentShape(RoundedRectangle(cornerRadius: 5))
            .onHover { isHovered = $0 }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AppChoiceMenuButton: NSViewRepresentable {
    let title: String
    let options: [InstalledApp]
    let emptyTitle: String
    let isSelected: (InstalledApp) -> Bool
    let select: (InstalledApp) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            title: title,
            options: options,
            emptyTitle: emptyTitle,
            isSelected: isSelected,
            select: select
        )
    }

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(
            title: AppMenuIcon.triggerTitle(title), target: context.coordinator,
            action: #selector(Coordinator.showMenu(_:)))
        button.isBordered = false
        button.alignment = .right
        button.controlSize = .regular
        button.image = AppMenuIcon.dropdownIndicator
        button.imagePosition = .imageTrailing
        button.imageHugsTitle = true
        button.imageScaling = .scaleNone
        button.lineBreakMode = .byTruncatingTail
        button.setButtonType(.momentaryPushIn)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        context.coordinator.button = button
        return button
    }

    func updateNSView(_ button: NSButton, context: Context) {
        button.title = AppMenuIcon.triggerTitle(title)
        button.image = AppMenuIcon.dropdownIndicator
        context.coordinator.title = title
        context.coordinator.options = options
        context.coordinator.emptyTitle = emptyTitle
        context.coordinator.isSelected = isSelected
        context.coordinator.select = select
        context.coordinator.button = button
    }

    final class Coordinator: NSObject {
        var title: String
        var options: [InstalledApp]
        var emptyTitle: String
        var isSelected: (InstalledApp) -> Bool
        var select: (InstalledApp) -> Void
        weak var button: NSButton?

        init(
            title: String,
            options: [InstalledApp],
            emptyTitle: String,
            isSelected: @escaping (InstalledApp) -> Bool,
            select: @escaping (InstalledApp) -> Void
        ) {
            self.title = title
            self.options = options
            self.emptyTitle = emptyTitle
            self.isSelected = isSelected
            self.select = select
        }

        @objc func showMenu(_ sender: NSButton) {
            let menu = NSMenu(title: title)
            menu.autoenablesItems = false
            menu.showsStateColumn = true
            var selectedItem: NSMenuItem?
            var selectedIndex: Int?

            if options.isEmpty {
                let item = NSMenuItem(title: emptyTitle, action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            } else {
                for app in options {
                    let selected = isSelected(app)
                    let item = NSMenuItem(
                        title: app.name, action: #selector(selectApp(_:)), keyEquivalent: "")
                    item.target = self
                    item.representedObject = app.bundleIdentifier
                    item.image = AppMenuIcon.image(for: app)
                    item.state = selected ? .on : .off
                    menu.addItem(item)

                    if selected {
                        selectedItem = item
                        selectedIndex = menu.items.count - 1
                    }
                }
            }

            let positioningItem =
                selectedIndex
                .flatMap { menu.items.indices.contains($0 + 1) ? menu.items[$0 + 1] : selectedItem }
                ?? menu.items.first
            let selectedItemVerticalAlignmentOffset: CGFloat = 4
            menu.popUp(
                positioning: positioningItem,
                at: NSPoint(x: 0, y: sender.bounds.height + selectedItemVerticalAlignmentOffset),
                in: sender
            )
        }

        @objc private func selectApp(_ sender: NSMenuItem) {
            guard let bundleIdentifier = sender.representedObject as? String,
                let app = options.first(where: { $0.bundleIdentifier == bundleIdentifier })
            else {
                return
            }
            select(app)
        }
    }
}

enum AppMenuIcon {
    static let dropdownIndicatorConfiguration = NSImage.SymbolConfiguration(
        pointSize: 8.5, weight: .regular, scale: .small)

    static func triggerTitle(_ title: String) -> String {
        "\(title) "
    }

    static var dropdownIndicator: NSImage? {
        guard
            let symbol = NSImage(
                systemSymbolName: "chevron.up.chevron.down", accessibilityDescription: nil)?
                .withSymbolConfiguration(dropdownIndicatorConfiguration)
        else {
            return nil
        }

        let canvasSize = NSSize(width: 10, height: 14)
        let symbolSize = NSSize(width: 8, height: 10)
        let image = NSImage(size: canvasSize)
        image.lockFocus()
        symbol.draw(
            in: NSRect(
                x: (canvasSize.width - symbolSize.width) / 2,
                y: (canvasSize.height - symbolSize.height) / 2,
                width: symbolSize.width,
                height: symbolSize.height
            ),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    static func image(for app: InstalledApp) -> NSImage {
        let image = app.icon.copy() as? NSImage ?? NSImage(size: NSSize(width: 16, height: 16))
        image.isTemplate = false
        image.size = NSSize(width: 16, height: 16)
        return image
    }
}
