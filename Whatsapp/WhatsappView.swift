import SwiftUI
import WebKit

struct WhatsAppWebView: NSViewRepresentable {
    @ObservedObject var webViewStore: WebViewStore
    
    func makeNSView(context: Context) -> WKWebView {
        return webViewStore.webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Não precisa fazer nada aqui
    }
}

class WebViewStore: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    
    let webView: WKWebView
    
    private let notificationManager = NotificationManager()
    
    override init() {
        // Configurar WKWebView
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        
        // Permitir persistência de dados
        let dataStore = WKWebsiteDataStore.default()
        configuration.websiteDataStore = dataStore
        
        // Configurar preferências
        let preferences = WKPreferences()
        configuration.preferences = preferences
        
        // Criar WebView
        webView = WKWebView(frame: .zero, configuration: configuration)
        
        super.init()
        
        // Configurar delegates
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.allowsAirPlayForMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")


        
        // User Agent customizado (compatível com WhatsApp Web)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        // Adicionar script para monitorar notificações
        setupNotificationMonitoring()
        
        // Carregar WhatsApp Web
        if let url = URL(string: "https://web.whatsapp.com") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.notificationManager.clearBadge()
        }

    }
    
    private func setupNotificationMonitoring() {
        let userContentController = webView.configuration.userContentController
        
        // Script para interceptar título da página (onde ficam as notificações)
        let titleObserverScript = """
        // Observar mudanças no título
        var lastTitle = document.title;
        
        setInterval(function() {
            if (document.title !== lastTitle) {
                lastTitle = document.title;
                window.webkit.messageHandlers.titleChanged.postMessage(document.title);
            }
        }, 1000);
        
        // Observar mudanças no favicon (indica nova mensagem)
        var lastFavicon = '';
        setInterval(function() {
            var favicon = document.querySelector('link[rel*="icon"]');
            if (favicon && favicon.href !== lastFavicon) {
                lastFavicon = favicon.href;
                window.webkit.messageHandlers.faviconChanged.postMessage(favicon.href);
            }
        }, 1000);
        """
        
        let script = WKUserScript(source: titleObserverScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(script)
        userContentController.add(self, name: "titleChanged")
        userContentController.add(self, name: "faviconChanged")
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentMessage(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "titleChanged", let title = message.body as? String {
            handleTitleChange(title)
        } else if message.name == "faviconChanged" {
            // Favicon mudou, pode indicar nova mensagem
            checkForNewMessages()
        }
    }
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if message.name == "titleChanged",
           let title = message.body as? String {
            handleTitleChange(title)
        } else if message.name == "faviconChanged" {
            checkForNewMessages()
        }
    }

    
    private func handleTitleChange(_ title: String) {

        if title == "WhatsApp" {
            notificationManager.clearBadge()
            return
        }

        if title.hasPrefix("(") {
            let components = title.components(separatedBy: ")")
            if let countString = components.first?.replacingOccurrences(of: "(", with: ""),
               let count = Int(countString) {
                notificationManager.showNotification(messageCount: count)
            }
        }
    }

    
    private func checkForNewMessages() {
        // Executar JavaScript para verificar se há novas mensagens
        let script = "document.title"
        webView.evaluateJavaScript(script) { [weak self] result, error in
            if let title = result as? String {
                self?.handleTitleChange(title)
            }
        }
    }
    

    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        updateNavigationState()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        updateNavigationState()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        updateNavigationState()
    }
    
    private func updateNavigationState() {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
    
    // MARK: - Public Methods
    
    func clearCookiesAndReload() {
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let date = Date(timeIntervalSince1970: 0)
        
        dataStore.removeData(ofTypes: dataTypes, modifiedSince: date) { [weak self] in
            DispatchQueue.main.async {
                if let url = URL(string: "https://web.whatsapp.com") {
                    let request = URLRequest(url: url)
                    self?.webView.load(request)
                }
            }
        }
    }
}
