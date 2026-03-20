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
        injectCustomStyles()
        
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
        
        let injectionJS = """
        (function() {
            // 1. Sobrescreve a API de Notificação do Navegador
            window.Notification = function(title, options) {
                window.webkit.messageHandlers.notificationHandler.postMessage({
                    title: title,
                    body: options ? options.body : ""
                });
                
                // Retorna um objeto "dummy" para não quebrar o script do WhatsApp
                return {
                    close: function() {},
                    onclick: function() {}
                };
            };
            
            // Mantém a permissão como 'granted' para o WhatsApp tentar enviar
            window.Notification.permission = 'granted';
            window.Notification.requestPermission = function(cb) {
                if (cb) cb('granted');
                return Promise.resolve('granted');
            };

            // 2. Observer de Título (Backup para o ícone do Dock)
            var target = document.querySelector('title');
            if (target) {
                var observer = new MutationObserver(function() {
                    window.webkit.messageHandlers.notificationHandler.postMessage({
                        type: "titleUpdate",
                        title: document.title
                    });
                });
                observer.observe(target, { subtree: true, characterData: true, childList: true });
            }
        })();
        """
        
        let script = WKUserScript(source: injectionJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.removeAllUserScripts()
        userContentController.addUserScript(script)
        
        userContentController.removeScriptMessageHandler(forName: "notificationHandler")
        userContentController.add(self, name: "notificationHandler")
        
        
    }
    
    private func injectCustomStyles() {
        // Seletor comum para o banner de download (pode variar, mas este cobre a maioria)
        let css = """
        /* Esconde o banner de 'Baixe o WhatsApp' */
        span[data-icon='down-context'],
        div._akau,
        div[role='alert'] + div > a[href*='download'] {
            display: none !important;
        }
        
        /* Remove a barra lateral de aviso de download se aparecer */
        .copyable-area + div[class*='_ak'] {
            display: none !important;
        }
        """
        
        let js = "var style = document.createElement('style'); style.innerHTML = `\(css)`; document.head.appendChild(style);"
        
        // Injeta o script para rodar toda vez que a página carregar
        let userScript = WKUserScript(
            source: js,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        webView.configuration.userContentController.addUserScript(userScript)
        
        _ = """
        img, [role='img'], [style*='border-radius: 50%'] {
            border-radius: 50% !important;
        }
        """
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
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "notificationHandler" else { return }
        
        if let dict = message.body as? [String: Any] {
            // Se for uma notificação real interceptada (Banner)
            if let title = dict["title"] as? String, let body = dict["body"] as? String {
                notificationManager.showImmediateNotification(title: title, body: body)
            }
            // Se for apenas o update do título (Badge no Dock)
            else if let type = dict["type"] as? String, type == "titleUpdate", let title = dict["title"] as? String {
                handleTitleChange(title)
            }
        }
    }

    
    private func handleTitleChange(_ title: String) {
        // Se o título voltou ao normal, limpamos o badge
        if title == "WhatsApp" || title == "WhatsApp" {
            notificationManager.clearBadge()
            return
        }

        // Procura por números entre parênteses usando RegEx simples ou componentes
        if title.contains("(") && title.contains(")") {
            let scanner = Scanner(string: title)
            _ = scanner.scanUpToString("(")
            _ = scanner.scanString("(")
            
            if let countString = scanner.scanUpToString(")"), let count = Int(countString) {
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
