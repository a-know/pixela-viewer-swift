import SwiftUI

struct GraphRowView: View {
    let graph: Graph
    let isCompact: Bool
    let isDarkMode: Bool
    let isEditing: Bool
    let isHidden: Bool
    let isPinned: Bool
    let onToggleVisibility: () -> Void
    let onTogglePin: () -> Void

    @State private var svgHeight: CGFloat = 120
    @State private var svgIsLoading = true
    @State private var stats: GraphStats?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardContent
                .opacity(isHidden ? 0.4 : 1.0)
                .onTapGesture {
                    guard !isEditing else { return }
                    openInBrowser()
                }

            if isEditing {
                VStack(spacing: 6) {
                    if !isHidden {
                        Button {
                            onTogglePin()
                        } label: {
                            Image(systemName: isPinned ? "pin.fill" : "pin")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(7)
                                .background(isPinned ? .orange.opacity(0.85) : .black.opacity(0.55))
                                .clipShape(Circle())
                        }
                    }
                    Button {
                        onToggleVisibility()
                    } label: {
                        Image(systemName: isHidden ? "eye.fill" : "eye.slash.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(.black.opacity(0.55))
                            .clipShape(Circle())
                    }
                }
                .padding(8)
            }
        }
        .task {
            await loadStats()
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            svgView
            statsView
        }
        .padding(8)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var header: some View {
        if isCompact {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(graph.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(graph.account.username)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.tint.opacity(0.15))
                    .foregroundStyle(.tint)
                    .clipShape(Capsule())
            }
        } else {
            HStack {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(graph.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Image(systemName: "arrow.up.right.square")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(graph.account.username)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.tint.opacity(0.15))
                    .foregroundStyle(.tint)
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var svgView: some View {
        if let url = graph.svgURL(isCompact: isCompact, isDarkMode: isDarkMode) {
            GeometryReader { proxy in
                ZStack {
                    AsyncSVGView(
                        url: url,
                        availableWidth: proxy.size.width,
                        onHeightMeasured: { height in svgHeight = height },
                        onSVGLoadComplete: { svgIsLoading = false }
                    )
                    .frame(width: proxy.size.width, height: svgHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    if svgIsLoading {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.secondary.opacity(0.12))
                            .frame(width: proxy.size.width, height: svgHeight)
                            .overlay { ProgressView() }
                            .transition(.opacity)
                    }
                }
            }
            .frame(height: svgHeight)
            .onChange(of: url) {
                svgIsLoading = true
            }
        }
    }

    @ViewBuilder
    private var statsView: some View {
        if let stats {
            Divider()
            if isCompact {
                HStack(spacing: 0) {
                    statItem(label: "今日", value: stats.todaysQuantity)
                    Spacer()
                    statItem(label: "昨日", value: stats.yesterdayQuantity)
                }
                .padding(.horizontal, 8)
            } else {
                HStack(spacing: 0) {
                    statItem(label: "今日", value: stats.todaysQuantity)
                    Spacer()
                    statItem(label: "昨日", value: stats.yesterdayQuantity)
                    Spacer()
                    Divider()
                        .frame(height: 28)
                    Spacer()
                    statItem(label: "最大", value: stats.maxQuantity)
                    Spacer()
                    statItem(label: "最小", value: stats.minQuantity)
                    Spacer()
                    statItem(label: "平均", value: stats.avgQuantity)
                }
                .padding(.horizontal, 8)
            }
        } else {
            // ロード中のプレースホルダー
            HStack {
                ProgressView()
                    .scaleEffect(0.7)
                Text("統計を取得中...")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statItem(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            (Text(formatQuantity(value)).font(.callout.bold())
                + Text(" \(graph.unit)").font(.caption2))
                .foregroundStyle(.primary)
        }
    }

    private func formatQuantity(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.2f", value)
    }

    private func loadStats() async {
        do {
            let token = try KeychainService.loadToken(for: graph.account.username)
            stats = try await PixelaAPIService.fetchGraphStats(for: graph, token: token)
        } catch {
            // スタッツ取得失敗はサイレントに無視（グラフ表示は継続）
        }
    }

    private func openInBrowser() {
        guard let url = graph.htmlURL() else { return }
        UIApplication.shared.open(url)
    }
}
