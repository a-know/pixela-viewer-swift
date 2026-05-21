import SwiftUI

struct GraphRowView: View {
    let graph: Graph
    let isCompact: Bool
    let isDarkMode: Bool
    let isEditing: Bool
    let isHidden: Bool
    let onToggleVisibility: () -> Void

    @State private var svgHeight: CGFloat = 200

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardContent
                .opacity(isHidden ? 0.4 : 1.0)
                .onTapGesture {
                    guard !isEditing else { return }
                    openInBrowser()
                }

            if isEditing {
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
                .padding(8)
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            svgView
        }
        .padding(8)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var header: some View {
        if isCompact {
            VStack(alignment: .leading, spacing: 4) {
                Text(graph.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(2)
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
                Text(graph.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
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
            if isCompact {
                AsyncSVGView(url: url)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                GeometryReader { proxy in
                    AsyncSVGView(
                        url: url,
                        availableWidth: proxy.size.width,
                        onHeightMeasured: { height in svgHeight = height }
                    )
                    .frame(width: proxy.size.width, height: svgHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(height: svgHeight)
            }
        }
    }

    private func openInBrowser() {
        guard let url = graph.htmlURL() else { return }
        UIApplication.shared.open(url)
    }
}
