import SwiftUI
import WebKit
import BayNavigatorCore

/// Content source for the WebView - either a URL or HTML string
public enum WebViewContent: Equatable {
    case url(URL)
    case html(String, baseURL: URL?)

    /// Create content from a URL string
    public static func urlString(_ string: String) -> WebViewContent? {
        guard let url = URL(string: string) else { return nil }
        return .url(url)
    }
}

/// Reusable WebView screen for displaying web content in-app
/// Supports iOS, macOS, and visionOS with platform-specific adaptations
public struct WebViewScreen: View {
    let title: String?
    let content: WebViewContent
    let accentColor: Color
    let allowsExternalNavigation: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel: WebViewViewModel

    @State private var showShareSheet = false

    /// Initialize with a URL
    /// - Parameters:
    ///   - title: Optional title to display (will use page title if nil)
    ///   - url: The URL to load
    ///   - accentColor: Accent color for UI elements
    ///   - allowsExternalNavigation: Whether to allow navigation to external URLs
    public init(
        title: String? = nil,
        url: URL,
        accentColor: Color = .appPrimary,
        allowsExternalNavigation: Bool = false
    ) {
        self.title = title
        self.content = .url(url)
        self.accentColor = accentColor
        self.allowsExternalNavigation = allowsExternalNavigation
        _viewModel = StateObject(wrappedValue: WebViewViewModel())
    }

    /// Initialize with content enum
    /// - Parameters:
    ///   - title: Optional title to display (will use page title if nil)
    ///   - content: The content to display (URL or HTML)
    ///   - accentColor: Accent color for UI elements
    ///   - allowsExternalNavigation: Whether to allow navigation to external URLs
    public init(
        title: String? = nil,
        content: WebViewContent,
        accentColor: Color = .appPrimary,
        allowsExternalNavigation: Bool = false
    ) {
        self.title = title
        self.content = content
        self.accentColor = accentColor
        self.allowsExternalNavigation = allowsExternalNavigation
        _viewModel = StateObject(wrappedValue: WebViewViewModel())
    }

    /// Initialize with a URL string
    /// - Parameters:
    ///   - title: Optional title to display (will use page title if nil)
    ///   - urlString: The URL string to load
    ///   - accentColor: Accent color for UI elements
    ///   - allowsExternalNavigation: Whether to allow navigation to external URLs
    public init(
        title: String? = nil,
        urlString: String,
        accentColor: Color = .appPrimary,
        allowsExternalNavigation: Bool = false
    ) {
        self.title = title
        self.content = URL(string: urlString).map { .url($0) } ?? .html("<p>Invalid URL</p>", baseURL: nil)
        self.accentColor = accentColor
        self.allowsExternalNavigation = allowsExternalNavigation
        _viewModel = StateObject(wrappedValue: WebViewViewModel())
    }

    /// Initialize with HTML content
    /// - Parameters:
    ///   - title: Optional title to display
    ///   - html: The HTML string to render
    ///   - baseURL: Optional base URL for resolving relative links
    ///   - accentColor: Accent color for UI elements
    public init(
        title: String? = nil,
        html: String,
        baseURL: URL? = nil,
        accentColor: Color = .appPrimary
    ) {
        self.title = title
        self.content = .html(html, baseURL: baseURL)
        self.accentColor = accentColor
        self.allowsExternalNavigation = false
        _viewModel = StateObject(wrappedValue: WebViewViewModel())
    }

    private var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        return viewModel.pageTitle ?? "Loading..."
    }

    private var currentURL: URL? {
        switch content {
        case .url(let url):
            return viewModel.currentURL ?? url
        case .html(_, let baseURL):
            return viewModel.currentURL ?? baseURL
        }
    }

    public var body: some View {
        ZStack {
            // Main content
            contentView

            // Loading progress bar at top
            if viewModel.isLoading {
                VStack {
                    ProgressView(value: viewModel.loadingProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: accentColor))
                        .frame(height: 2)
                    Spacer()
                }
            }
        }
        .navigationTitle(displayTitle)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                toolbarButtons
            }
            ToolbarItemGroup(placement: .bottomBar) {
                navigationButtons
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = currentURL {
                WebViewShareSheet(items: [url])
            }
        }
        #elseif os(macOS)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                navigationButtons
                Divider()
                toolbarButtons
            }
        }
        #elseif os(visionOS)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                toolbarButtons
            }
            ToolbarItemGroup(placement: .bottomOrnament) {
                navigationButtons
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = currentURL {
                WebViewShareSheet(items: [url])
            }
        }
        #endif
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .loading, .loaded:
            WebViewRepresentable(
                content: content,
                viewModel: viewModel,
                colorScheme: colorScheme,
                allowsExternalNavigation: allowsExternalNavigation,
                onExternalLink: { url in
                    openURL(url)
                }
            )
            .ignoresSafeArea(edges: .bottom)

        case .error(let message):
            errorView(message: message)
        }
    }

    // MARK: - Toolbar Buttons

    @ViewBuilder
    private var toolbarButtons: some View {
        Button {
            viewModel.reload()
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(viewModel.isLoading)
        .help("Refresh")

        if case .url = content {
            Button {
                if let url = currentURL {
                    openURL(url)
                }
            } label: {
                Image(systemName: "safari")
            }
            .help("Open in Safari")
        }

        #if os(iOS) || os(visionOS)
        Button {
            showShareSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .disabled(currentURL == nil)
        .help("Share")
        #else
        if let url = currentURL {
            ShareLink(item: url) {
                Image(systemName: "square.and.arrow.up")
            }
        }
        #endif
    }

    // MARK: - Navigation Buttons

    @ViewBuilder
    private var navigationButtons: some View {
        Button {
            viewModel.goBack()
        } label: {
            Image(systemName: "chevron.left")
        }
        .disabled(!viewModel.canGoBack)
        .help("Go Back")

        Button {
            viewModel.goForward()
        } label: {
            Image(systemName: "chevron.right")
        }
        .disabled(!viewModel.canGoForward)
        .help("Go Forward")

        Spacer()

        if viewModel.isLoading {
            Button {
                viewModel.stopLoading()
            } label: {
                Image(systemName: "xmark")
            }
            .help("Stop Loading")
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 64))
                .foregroundStyle(colorScheme == .dark ? Color.darkTextSecondary : Color.lightTextSecondary)

            Text("Unable to load page")
                .font(.title2.bold())

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button {
                    viewModel.retry(content: content)
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)

                if case .url(let url) = content {
                    Button {
                        openURL(url)
                    } label: {
                        Label("Open in Safari", systemImage: "safari")
                            .frame(maxWidth: 200)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - WebView ViewModel

@MainActor
final class WebViewViewModel: ObservableObject {
    enum State {
        case loading
        case loaded
        case error(String)
    }

    @Published var state: State = .loading
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var pageTitle: String?
    @Published var currentURL: URL?

    weak var webView: WKWebView?

    func reload() {
        webView?.reload()
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func stopLoading() {
        webView?.stopLoading()
    }

    func retry(content: WebViewContent) {
        state = .loading
        switch content {
        case .url(let url):
            webView?.load(URLRequest(url: url))
        case .html(let html, let baseURL):
            webView?.loadHTMLString(html, baseURL: baseURL)
        }
    }
}

// MARK: - Platform-specific WebView Representable

#if os(iOS) || os(visionOS)
struct WebViewRepresentable: UIViewRepresentable {
    let content: WebViewContent
    let viewModel: WebViewViewModel
    let colorScheme: ColorScheme
    let allowsExternalNavigation: Bool
    let onExternalLink: (URL) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        // Set up appearance
        webView.isOpaque = false
        webView.backgroundColor = colorScheme == .dark ? UIColor(Color.darkBackground) : UIColor(Color.lightBackground)
        webView.scrollView.backgroundColor = webView.backgroundColor

        // Store reference in view model
        Task { @MainActor in
            viewModel.webView = webView
        }

        // Add observers
        context.coordinator.observeWebView(webView)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only load content if not already loaded
        if context.coordinator.hasLoaded { return }
        context.coordinator.hasLoaded = true

        switch content {
        case .url(let url):
            webView.load(URLRequest(url: url))
        case .html(let html, let baseURL):
            let styledHTML = wrapHTMLWithStyles(html)
            webView.loadHTMLString(styledHTML, baseURL: baseURL)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, allowsExternalNavigation: allowsExternalNavigation, onExternalLink: onExternalLink)
    }

    private func wrapHTMLWithStyles(_ html: String) -> String {
        let isDark = colorScheme == .dark
        let bgColor = isDark ? "#0D1117" : "#F9FAFB"
        let textColor = isDark ? "#E8EEF5" : "#24292E"
        let linkColor = "#00ACC1"

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=5, user-scalable=yes">
            <style>
                * { box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 17px;
                    line-height: 1.6;
                    color: \(textColor);
                    background-color: \(bgColor);
                    padding: 16px;
                    margin: 0;
                    -webkit-text-size-adjust: 100%;
                }
                a { color: \(linkColor); text-decoration: underline; }
                img { max-width: 100%; height: auto; }
            </style>
        </head>
        <body>
            \(html)
        </body>
        </html>
        """
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let viewModel: WebViewViewModel
        let allowsExternalNavigation: Bool
        let onExternalLink: (URL) -> Void
        var hasLoaded = false

        private var progressObservation: NSKeyValueObservation?
        private var titleObservation: NSKeyValueObservation?
        private var urlObservation: NSKeyValueObservation?
        private var canGoBackObservation: NSKeyValueObservation?
        private var canGoForwardObservation: NSKeyValueObservation?

        init(viewModel: WebViewViewModel, allowsExternalNavigation: Bool, onExternalLink: @escaping (URL) -> Void) {
            self.viewModel = viewModel
            self.allowsExternalNavigation = allowsExternalNavigation
            self.onExternalLink = onExternalLink
        }

        func observeWebView(_ webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.loadingProgress = webView.estimatedProgress
                }
            }

            titleObservation = webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.pageTitle = webView.title
                }
            }

            urlObservation = webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.currentURL = webView.url
                }
            }

            canGoBackObservation = webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.canGoBack = webView.canGoBack
                }
            }

            canGoForwardObservation = webView.observe(\.canGoForward, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.canGoForward = webView.canGoForward
                }
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                viewModel.isLoading = true
                viewModel.state = .loading
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                viewModel.isLoading = false
                viewModel.state = .loaded
                viewModel.loadingProgress = 1.0
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleError(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleError(error)
        }

        private func handleError(_ error: Error) {
            let nsError = error as NSError

            // Ignore cancelled requests (e.g., user navigated away)
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                return
            }

            Task { @MainActor in
                viewModel.isLoading = false

                let message: String
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet:
                    message = "No internet connection. Please check your network and try again."
                case NSURLErrorTimedOut:
                    message = "The request timed out. Please try again."
                case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                    message = "Unable to connect to the server. Please try again later."
                case NSURLErrorSecureConnectionFailed:
                    message = "A secure connection could not be established."
                default:
                    message = "Failed to load the page. Please try again."
                }

                viewModel.state = .error(message)
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Handle special URL schemes
            let scheme = url.scheme?.lowercased() ?? ""
            if ["tel", "mailto", "sms", "facetime"].contains(scheme) {
                onExternalLink(url)
                decisionHandler(.cancel)
                return
            }

            // For link clicks, check if we should open externally
            if navigationAction.navigationType == .linkActivated {
                // Allow navigation within baynavigator.org
                if let host = url.host?.lowercased(), host.contains("baynavigator.org") {
                    decisionHandler(.allow)
                    return
                }

                // Open external links in browser if not allowing external navigation
                if !allowsExternalNavigation {
                    onExternalLink(url)
                    decisionHandler(.cancel)
                    return
                }
            }

            decisionHandler(.allow)
        }
    }
}
#endif

#if os(macOS)
struct WebViewRepresentable: NSViewRepresentable {
    let content: WebViewContent
    let viewModel: WebViewViewModel
    let colorScheme: ColorScheme
    let allowsExternalNavigation: Bool
    let onExternalLink: (URL) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        // Store reference in view model
        Task { @MainActor in
            viewModel.webView = webView
        }

        // Add observers
        context.coordinator.observeWebView(webView)

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Only load content if not already loaded
        if context.coordinator.hasLoaded { return }
        context.coordinator.hasLoaded = true

        switch content {
        case .url(let url):
            webView.load(URLRequest(url: url))
        case .html(let html, let baseURL):
            let styledHTML = wrapHTMLWithStyles(html)
            webView.loadHTMLString(styledHTML, baseURL: baseURL)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, allowsExternalNavigation: allowsExternalNavigation, onExternalLink: onExternalLink)
    }

    private func wrapHTMLWithStyles(_ html: String) -> String {
        let isDark = colorScheme == .dark
        let bgColor = isDark ? "#0D1117" : "#F9FAFB"
        let textColor = isDark ? "#E8EEF5" : "#24292E"
        let linkColor = "#00ACC1"

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                * { box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 15px;
                    line-height: 1.6;
                    color: \(textColor);
                    background-color: \(bgColor);
                    padding: 16px;
                    margin: 0;
                }
                a { color: \(linkColor); text-decoration: underline; }
                img { max-width: 100%; height: auto; }
            </style>
        </head>
        <body>
            \(html)
        </body>
        </html>
        """
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let viewModel: WebViewViewModel
        let allowsExternalNavigation: Bool
        let onExternalLink: (URL) -> Void
        var hasLoaded = false

        private var progressObservation: NSKeyValueObservation?
        private var titleObservation: NSKeyValueObservation?
        private var urlObservation: NSKeyValueObservation?
        private var canGoBackObservation: NSKeyValueObservation?
        private var canGoForwardObservation: NSKeyValueObservation?

        init(viewModel: WebViewViewModel, allowsExternalNavigation: Bool, onExternalLink: @escaping (URL) -> Void) {
            self.viewModel = viewModel
            self.allowsExternalNavigation = allowsExternalNavigation
            self.onExternalLink = onExternalLink
        }

        func observeWebView(_ webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.loadingProgress = webView.estimatedProgress
                }
            }

            titleObservation = webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.pageTitle = webView.title
                }
            }

            urlObservation = webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.currentURL = webView.url
                }
            }

            canGoBackObservation = webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.canGoBack = webView.canGoBack
                }
            }

            canGoForwardObservation = webView.observe(\.canGoForward, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.viewModel.canGoForward = webView.canGoForward
                }
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                viewModel.isLoading = true
                viewModel.state = .loading
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                viewModel.isLoading = false
                viewModel.state = .loaded
                viewModel.loadingProgress = 1.0
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleError(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleError(error)
        }

        private func handleError(_ error: Error) {
            let nsError = error as NSError

            // Ignore cancelled requests
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                return
            }

            Task { @MainActor in
                viewModel.isLoading = false

                let message: String
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet:
                    message = "No internet connection. Please check your network and try again."
                case NSURLErrorTimedOut:
                    message = "The request timed out. Please try again."
                case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                    message = "Unable to connect to the server. Please try again later."
                case NSURLErrorSecureConnectionFailed:
                    message = "A secure connection could not be established."
                default:
                    message = "Failed to load the page. Please try again."
                }

                viewModel.state = .error(message)
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Handle special URL schemes
            let scheme = url.scheme?.lowercased() ?? ""
            if ["tel", "mailto", "sms", "facetime"].contains(scheme) {
                onExternalLink(url)
                decisionHandler(.cancel)
                return
            }

            // For link clicks, check if we should open externally
            if navigationAction.navigationType == .linkActivated {
                // Allow navigation within baynavigator.org
                if let host = url.host?.lowercased(), host.contains("baynavigator.org") {
                    decisionHandler(.allow)
                    return
                }

                // Open external links in browser if not allowing external navigation
                if !allowsExternalNavigation {
                    onExternalLink(url)
                    decisionHandler(.cancel)
                    return
                }
            }

            decisionHandler(.allow)
        }
    }
}
#endif

// MARK: - iOS/visionOS Share Sheet

#if os(iOS) || os(visionOS)
private struct WebViewShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - Convenience Extensions

extension WebViewScreen {
    /// Create a WebViewScreen for displaying terms of service
    public static func termsOfService() -> WebViewScreen {
        WebViewScreen(
            title: "Terms of Service",
            urlString: "https://baynavigator.org/terms"
        )
    }

    /// Create a WebViewScreen for displaying privacy policy
    public static func privacyPolicy() -> WebViewScreen {
        WebViewScreen(
            title: "Privacy Policy",
            urlString: "https://baynavigator.org/privacy"
        )
    }

    /// Create a WebViewScreen for displaying a guide as fallback
    public static func guideFallback(title: String, guideId: String, accentColor: Color = .appPrimary) -> WebViewScreen {
        WebViewScreen(
            title: title,
            urlString: "https://baynavigator.org/guides/\(guideId)",
            accentColor: accentColor
        )
    }
}

// MARK: - Preview

#Preview("URL Content") {
    NavigationStack {
        WebViewScreen(
            title: "BayNavigator",
            urlString: "https://baynavigator.org"
        )
    }
}

#Preview("HTML Content") {
    NavigationStack {
        WebViewScreen(
            title: "HTML Example",
            html: """
            <h1>Welcome to BayNavigator</h1>
            <p>This is an example of HTML content rendered in the WebView.</p>
            <p>You can include <a href="https://baynavigator.org">links</a> and other HTML elements.</p>
            <ul>
                <li>Item 1</li>
                <li>Item 2</li>
                <li>Item 3</li>
            </ul>
            """
        )
    }
}

#Preview("Privacy Policy") {
    NavigationStack {
        WebViewScreen.privacyPolicy()
    }
}
