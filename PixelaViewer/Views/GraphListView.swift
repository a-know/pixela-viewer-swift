import SwiftUI

struct GraphListView: View {
    @EnvironmentObject private var accountStore: AccountStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isEditing = false

    private var isCompact: Bool { horizontalSizeClass == .compact }
    private var isDarkMode: Bool { colorScheme == .dark }

    private var columns: [GridItem] {
        isCompact
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible())]
    }

    var body: some View {
        Group {
            if accountStore.accounts.isEmpty {
                emptyAccountsView
            } else if accountStore.isLoading {
                ProgressView("グラフを読み込み中...")
            } else if accountStore.graphs.isEmpty && accountStore.hasServerError {
                serverErrorView
            } else if accountStore.graphs.isEmpty {
                emptyGraphsView
            } else {
                graphList
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !accountStore.graphs.isEmpty {
                    Button(isEditing ? "完了" : "編集") {
                        isEditing.toggle()
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !accountStore.hiddenGraphs.isEmpty || accountStore.showHidden {
                    Button {
                        accountStore.showHidden.toggle()
                    } label: {
                        Image(systemName: accountStore.showHidden ? "eye" : "eye.slash")
                    }
                }
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

    private var serverErrorView: some View {
        ContentUnavailableView {
            Label("読み込みに失敗しました", systemImage: "exclamationmark.triangle")
        } description: {
            Text("サーバーエラーが発生しました。\nしばらく時間をおいてから再読み込みしてください。")
        } actions: {
            Button(action: { Task { await accountStore.fetchAllGraphs() } }) {
                Label("再読み込み", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var serverErrorBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("一部のグラフの読み込みに失敗しました")
                .font(.caption)
                .foregroundStyle(.primary)
            Spacer()
            Button {
                Task { await accountStore.fetchAllGraphs() }
            } label: {
                Label("再読み込み", systemImage: "arrow.clockwise")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.orange.opacity(0.12))
    }

    private var graphList: some View {
        ScrollView {
            if accountStore.hasServerError {
                serverErrorBanner
            }
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(accountStore.visibleGraphs) { graph in
                    GraphRowView(
                        graph: graph,
                        isCompact: isCompact,
                        isDarkMode: isDarkMode,
                        isEditing: isEditing,
                        isHidden: false
                    ) {
                        accountStore.hideGraph(graph)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            if accountStore.showHidden && !accountStore.hiddenGraphs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("非表示のグラフ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(accountStore.hiddenGraphs) { graph in
                            GraphRowView(
                                graph: graph,
                                isCompact: isCompact,
                                isDarkMode: isDarkMode,
                                isEditing: isEditing,
                                isHidden: true
                            ) {
                                accountStore.unhideGraph(graph)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8)
            }

            Spacer().frame(height: 16)
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
