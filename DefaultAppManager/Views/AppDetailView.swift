import SwiftUI

struct AppDetailView: View {
    @EnvironmentObject private var store: AppStore
    let app: InstalledApp
    @State private var showingAddSheet = false

    private var assignedFileTypes: [FileType] {
        store.assignedFileTypes(for: app)
    }

    private var selectedFileType: FileType? {
        guard let id = store.selectedAppFileTypeID else {
            return nil
        }
        return FileTypeCatalog.fileType(for: id)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 18)

            Divider()

            VStack(spacing: 0) {
                List(selection: $store.selectedAppFileTypeID) {
                    ForEach(assignedFileTypes) { fileType in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fileType.displayName)
                            Text("\(fileType.primaryExtension)  \(fileType.utiIdentifier)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.leading, 6)
                        .padding(.trailing, 6)
                        .tag(fileType.id)
                    }
                }
                .listStyle(.inset)

                Divider()

                HStack(spacing: 8) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .help("Add a file type default for \(app.name)")

                    Button {
                        if let selectedFileType {
                            store.restorePreviousDefault(for: selectedFileType)
                        }
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedFileType.map { !store.canRestorePreviousDefault(for: $0) } ?? true)
                    .help("Restore the previously recorded default app")

                    Spacer()

                    if let selectedFileType, !store.canRestorePreviousDefault(for: selectedFileType) {
                        Text("No previous default recorded for the selected file type.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingAddSheet) {
            AddFileTypeSheet(app: app)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.title2.weight(.semibold))
                CopyableBundleIdentifierText(bundleIdentifier: app.bundleIdentifier)
            }

            Spacer()
        }
    }
}

struct AddFileTypeSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let app: InstalledApp
    @State private var categoryID = FileTypeCatalog.categories[0].id
    @State private var fileTypeID = FileTypeCatalog.categories[0].fileTypes[0].id

    private var selectedCategory: FileTypeCategory {
        store.category(for: categoryID) ?? store.categories[0]
    }

    private var selectedFileType: FileType {
        selectedCategory.fileTypes.first { $0.id == fileTypeID } ?? selectedCategory.fileTypes[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Add File Type")
                .font(.title3.weight(.semibold))

            Picker("Category", selection: $categoryID) {
                ForEach(store.categories) { category in
                    Text(category.name).tag(category.id)
                }
            }
            .onChange(of: categoryID) { _, newValue in
                if let category = store.category(for: newValue) {
                    fileTypeID = category.fileTypes[0].id
                }
            }

            Picker("File Type", selection: $fileTypeID) {
                ForEach(selectedCategory.fileTypes) { fileType in
                    Text("\(fileType.displayName) (\(fileType.primaryExtension))").tag(fileType.id)
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Assign") {
                    store.setDefault(app: app, for: selectedFileType)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420, height: 230)
    }
}
