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
        .alert("LaunchServices Error", isPresented: errorBinding) {
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
                    Section("File Types") {
                        ForEach(store.filteredCategories) { category in
                            Label(category.name, systemImage: category.systemImage)
                                .tag(SidebarSelection.category(category.id))
                        }
                    }

                    Section("Applications") {
                        ForEach(store.filteredApps) { app in
                            HStack(spacing: 8) {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(app.name)
                                        .lineLimit(1)
                                    Text(app.bundleIdentifier)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .tag(SidebarSelection.app(app.bundleIdentifier))
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .searchable(text: $store.searchText, placement: .sidebar, prompt: "Search")
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

struct EmptyStateView: View {
    let title: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
