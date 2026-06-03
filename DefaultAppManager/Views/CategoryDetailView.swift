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
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                ForEach(store.apps) { app in
                    Button {
                        store.setDefault(app: app, for: category)
                    } label: {
                        AppMenuLabel(app: app, isSelected: false)
                    }
                }
            } label: {
                Text("Set All")
                    .frame(minWidth: 190, idealWidth: 220, maxWidth: 260, alignment: .trailing)
            }
            .menuStyle(.borderlessButton)
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
                    CopyableBundleIdentifierText(bundleIdentifier: fileType.utiIdentifier, textStyle: .caption)
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
        Menu {
            let options = store.appOptions(for: fileType)
            if options.isEmpty {
                Text("No registered apps")
            } else {
                ForEach(options) { app in
                    Button {
                        store.setDefault(app: app, for: fileType)
                    } label: {
                        AppMenuLabel(app: app, isSelected: store.currentHandlers[fileType.id] == app.bundleIdentifier)
                    }
                }
            }
        } label: {
            Text(store.currentAppName(for: fileType))
                .lineLimit(1)
                .truncationMode(.tail)
            .frame(minWidth: 190, idealWidth: 220, maxWidth: 260, alignment: .trailing)
        }
        .menuStyle(.borderlessButton)
        .fixedSize(horizontal: true, vertical: false)
        .help("Choose the default app for \(fileType.displayName)")
    }
}

struct AppMenuLabel: View {
    let app: InstalledApp
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "checkmark")
                .opacity(isSelected ? 1 : 0)
                .frame(width: 14)

            AppIconImage(app: app, size: 16)

            Text(app.name)
        }
    }
}

struct AppIconImage: View {
    let app: InstalledApp
    let size: CGFloat

    var body: some View {
        Image(nsImage: nonTemplateIcon)
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
    }

    private var nonTemplateIcon: NSImage {
        let image = app.icon.copy() as? NSImage ?? app.icon
        image.isTemplate = false
        return image
    }
}
