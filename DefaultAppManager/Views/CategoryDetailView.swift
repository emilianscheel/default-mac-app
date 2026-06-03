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
            }
            .listStyle(.inset)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: category.systemImage)
                .font(.system(size: 32, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 44, height: 44)

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
                        Text(app.name)
                    }
                }
            } label: {
                Label("Set All", systemImage: "checklist")
            }
            .menuStyle(.borderedButton)
            .help("Set the default opening app for every file type in \(category.name)")
        }
    }
}

struct FileTypeAssignmentRow: View {
    @EnvironmentObject private var store: AppStore
    let fileType: FileType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: fileType.systemImage)
                .font(.system(size: 19))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(fileType.displayName)
                    .font(.body)
                Text(([fileType.primaryExtension] + [fileType.utiIdentifier]).joined(separator: "  "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                        Label(app.name, systemImage: store.currentHandlers[fileType.id] == app.bundleIdentifier ? "checkmark" : "app")
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(store.currentAppName(for: fileType))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 190, idealWidth: 220, maxWidth: 260, alignment: .trailing)
        }
        .menuStyle(.borderlessButton)
        .fixedSize(horizontal: true, vertical: false)
        .help("Choose the default app for \(fileType.displayName)")
    }
}
