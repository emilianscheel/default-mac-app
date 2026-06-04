import SwiftUI

struct SettingsRootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 230, ideal: 280, max: 360)
        } detail: {
            DetailView()
        }
        .alert("App Error", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                store.errorMessage = nil
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )
    }
}

struct SidebarView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.hasNoSidebarSearchResults {
                SidebarNoResultsView(query: store.sidebarSearchQuery)
            } else {
                List(selection: $store.selection) {
                    if store.shouldShowSettingsInSidebar {
                        Label("Settings", systemImage: "gearshape")
                            .tag(SidebarSelection.settings)
                    }

                    if !store.sidebarCategoryResults.isEmpty {
                        Section("File Types") {
                            ForEach(store.sidebarCategoryResults) { result in
                                SidebarResultRow(
                                    title: result.category.name,
                                    subtitle: resultSubtitle(count: result.resultCount),
                                    systemImage: result.category.systemImage
                                )
                                    .tag(SidebarSelection.category(result.category.id))
                            }
                        }
                    }

                    if !store.sidebarAppResults.isEmpty {
                        Section("Applications") {
                            ForEach(store.sidebarAppResults) { result in
                                SidebarResultRow(
                                    title: result.app.name,
                                    subtitle: resultSubtitle(count: result.resultCount),
                                    nsImage: result.app.icon
                                )
                                .tag(SidebarSelection.app(result.app.bundleIdentifier))
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .searchable(text: $store.searchText, placement: .sidebar, prompt: "Search")
    }

    private func resultSubtitle(count: Int) -> String? {
        guard !store.sidebarSearchQuery.isEmpty else {
            return nil
        }
        return count == 1 ? "1 result" : "\(count) results"
    }
}

struct SidebarResultRow: View {
    let title: String
    let subtitle: String?
    let systemImage: String?
    let nsImage: NSImage?

    init(title: String, subtitle: String?, systemImage: String) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.nsImage = nil
    }

    init(title: String, subtitle: String?, nsImage: NSImage) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = nil
        self.nsImage = nsImage
    }

    var body: some View {
        HStack(spacing: 8) {
            icon
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    private var icon: some View {
        if let nsImage {
            Image(nsImage: nsImage)
                .resizable()
        } else if let systemImage {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
        }
    }
}

struct SidebarNoResultsView: View {
    let query: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.secondary)
            Text("No Results for \"\(query)\"")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct DetailView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        switch store.selection {
        case .settings:
            SettingsDetailView()
        case .category(let id):
            if let category = store.category(for: id) {
                CategoryDetailView(category: category)
            } else {
                EmptyStateView(title: "Select a file type", systemImage: "doc.text")
            }
        case .app(let bundleIdentifier):
            if let app = store.app(for: bundleIdentifier) {
                AppDetailView(app: app)
            } else {
                EmptyStateView(title: "Select an application", systemImage: "app")
            }
        case nil:
            EmptyStateView(title: "Select a category or app", systemImage: "sidebar.left")
        }
    }
}

struct SettingsDetailView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 18)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Show in Menu Bar", isOn: showInMenuBarBinding)
                    .toggleStyle(.checkbox)
                Toggle("Open on Login", isOn: openOnLoginBinding)
                    .toggleStyle(.checkbox)
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            Text("Settings")
                .font(.title2.weight(.semibold))
            Spacer()
        }
    }

    private var showInMenuBarBinding: Binding<Bool> {
        Binding(
            get: { store.showInMenuBar },
            set: { store.setShowInMenuBar($0) }
        )
    }

    private var openOnLoginBinding: Binding<Bool> {
        Binding(
            get: { store.openOnLogin },
            set: { store.setOpenOnLogin($0) }
        )
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
