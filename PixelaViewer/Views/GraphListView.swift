import SwiftUI

struct GraphListView: View {
    @EnvironmentObject private var accountStore: AccountStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    var body: some View {
        Group {
            if accountStore.accounts.isEmpty {
                emptyAccountsView
            } else if accountStore.isLoading {
                ProgressView("グラフを読み込み中...")
            } else if accountStore.graphs.isEmpty {
                emptyGraphsView
            } else {
                graphList
            }
        }
        .alert("エラー", isPresented: Binding(
            get: { accountStore.error != nil },
            set: { if !$0 { accountStore.error = nil } }
        )) {
            Button("OK", role: .cancel) { accountStore.error = nil }
        } message: {
            Text(accountStore.error ?? "")
        }
        .refreshable {
            await accountStore.fetchAllGraphs()
        }
    }

    private var columns: [GridItem] {
        isCompact
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]
    }

    private var graphList: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(accountStore.graphs) { graph in
                    GraphRowView(graph: graph, isCompact: isCompact, isDarkMode: isDarkMode)
                }
            }
            .padding(16)
        }
    }

    private var emptyAccountsView: some View {
        ContentUnavailableView(
            "アカウントが登録されていません",
            systemImage: "person.badge.plus",
            description: Text("右上のボタンからアカウントを追加してください")
        )
    }

    private var emptyGraphsView: some View {
        ContentUnavailableView(
            "グラフが見つかりません",
            systemImage: "chart.bar.xaxis",
            description: Text("登録されたアカウントにグラフがありません")
        )
    }
}
