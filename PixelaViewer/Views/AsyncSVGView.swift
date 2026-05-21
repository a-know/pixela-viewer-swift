import SwiftUI
import WebKit

struct AsyncSVGView: UIViewRepresentable {
    let url: URL
    let availableWidth: CGFloat
    let onHeightMeasured: ((CGFloat) -> Void)?

    init(url: URL, availableWidth: CGFloat = 0, onHeightMeasured: ((CGFloat) -> Void)? = nil) {
        self.url = url
        self.availableWidth = availableWidth
        self.onHeightMeasured = onHeightMeasured
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(
            WeakScriptMessageHandler(context.coordinator),
            name: "aspectRatio"
        )
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isUserInteractionEnabled = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.availableWidth = availableWidth
        context.coordinator.onHeightMeasured = onHeightMeasured
        guard context.coordinator.loadedURL != url else { return }
        context.coordinator.loadedURL = url
        webView.loadHTMLString(makeHTML(url: url, reportRatio: availableWidth > 0), baseURL: url)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "aspectRatio")
    }

    private func makeHTML(url: URL, reportRatio: Bool) -> String {
        let script = reportRatio ? """
        <script>
        var img = document.getElementById('g');
        function report() {
            if (img.naturalWidth > 0) {
                window.webkit.messageHandlers.aspectRatio.postMessage(img.naturalHeight / img.naturalWidth);
            }
        }
        img.addEventListener('load', report);
        if (img.complete && img.naturalWidth > 0) report();
        </script>
        """ : ""

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { width: 100%; overflow: hidden; background: transparent; }
        img { width: 100%; height: auto; display: block; }
        </style>
        </head>
        <body><img id="g" src="\(url.absoluteString)">\(script)</body>
        </html>
        """
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var loadedURL: URL?
        var availableWidth: CGFloat = 0
        var onHeightMeasured: ((CGFloat) -> Void)?

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "aspectRatio",
                  let ratio = message.body as? Double,
                  ratio > 0,
                  availableWidth > 0 else { return }
            let height = availableWidth * ratio
            DispatchQueue.main.async { [weak self] in
                self?.onHeightMeasured?(height)
            }
        }
    }
}

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(_ delegate: WKScriptMessageHandler) { self.delegate = delegate }
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(controller, didReceive: message)
    }
}
