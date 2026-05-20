import SwiftUI

struct GraphRowView: View {
    let graph: Graph
    let isCompact: Bool
    let isDarkMode: Bool

    var body: some View {
        Button {
            openInBrowser()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
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

                if let url = graph.svgURL(isCompact: isCompact, isDarkMode: isDarkMode) {
                    AsyncSVGView(url: url)
                        .frame(maxWidth: .infinity)
                        .frame(height: isCompact ? 100 : 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func openInBrowser() {
        guard let url = graph.htmlURL() else { return }
        UIApplication.shared.open(url)
    }
}
