import SwiftUI
import WebKit

struct AsyncSVGView: UIViewRepresentable {
    let url: URL
    let availableWidth: CGFloat
    let onHeightMeasured: ((CGFloat) -> Void)?
    let onSVGLoadComplete: (() -> Void)?

    init(url: URL, availableWidth: CGFloat = 0, onHeightMeasured: ((CGFloat) -> Void)? = nil, onSVGLoadComplete: (() -> Void)? = nil) {
        self.url = url
        self.availableWidth = availableWidth
        self.onHeightMeasured = onHeightMeasured
        self.onSVGLoadComplete = onSVGLoadComplete
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
        config.userContentController.add(
            WeakScriptMessageHandler(context.coordinator),
            name: "svgDidLoad"
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
        let prevWidth = context.coordinator.availableWidth
        context.coordinator.availableWidth = availableWidth
        context.coordinator.onHeightMeasured = onHeightMeasured
        context.coordinator.onSVGLoadComplete = onSVGLoadComplete

        if availableWidth > 0, prevWidth != availableWidth, context.coordinator.lastRatio > 0 {
            let newHeight = availableWidth * context.coordinator.lastRatio
            let callback = onHeightMeasured
            DispatchQueue.main.async { callback?(newHeight) }
        }

        guard context.coordinator.loadedURL != url else { return }
        context.coordinator.loadedURL = url
        webView.loadHTMLString(makeHTML(url: url, reportRatio: availableWidth > 0), baseURL: url)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "aspectRatio")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "svgDidLoad")
    }

    private func makeHTML(url: URL, reportRatio: Bool) -> String {
        let ratioJS = reportRatio ? """
        if (img.naturalWidth > 0) {
            window.webkit.messageHandlers.aspectRatio.postMessage(img.naturalHeight / img.naturalWidth);
        }
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
        <body>
        <img id="g" src="\(url.absoluteString)">
        <script>
        var img = document.getElementById('g');
        function onLoad() {
            \(ratioJS)
            window.webkit.messageHandlers.svgDidLoad.postMessage(true);
        }
        img.addEventListener('load', onLoad);
        img.addEventListener('error', function() {
            window.webkit.messageHandlers.svgDidLoad.postMessage(false);
        });
        if (img.complete && img.naturalWidth > 0) onLoad();
        </script>
        </body>
        </html>
        """
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var loadedURL: URL?
        var availableWidth: CGFloat = 0
        var lastRatio: Double = 0
        var onHeightMeasured: ((CGFloat) -> Void)?
        var onSVGLoadComplete: (() -> Void)?

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "aspectRatio",
               let ratio = message.body as? Double,
               ratio > 0,
               availableWidth > 0 {
                lastRatio = ratio
                let height = availableWidth * ratio
                DispatchQueue.main.async { [weak self] in
                    self?.onHeightMeasured?(height)
                }
            } else if message.name == "svgDidLoad" {
                DispatchQueue.main.async { [weak self] in
                    self?.onSVGLoadComplete?()
                }
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
