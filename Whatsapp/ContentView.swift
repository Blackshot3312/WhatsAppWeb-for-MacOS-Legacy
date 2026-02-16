import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var webViewStore = WebViewStore()
    
    var body: some View {
        VStack(spacing: 0) {
            // Barra de navegação customizada
            HStack {
                Button(action: {
                    webViewStore.webView.goBack()
                }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!webViewStore.canGoBack)
                
                Button(action: {
                    webViewStore.webView.goForward()
                }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!webViewStore.canGoForward)
                
                Button(action: {
                    webViewStore.webView.reload()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                
                Spacer()
                
                if webViewStore.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                
                Spacer()
                
                Button(action: {
                    webViewStore.clearCookiesAndReload()
                }) {
                    Label("Limpar Sessão", systemImage: "trash")
                }
                .help("Limpar cookies e recarregar")
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // WebView
            WhatsAppWebView(webViewStore: webViewStore)
        }
    }
}



