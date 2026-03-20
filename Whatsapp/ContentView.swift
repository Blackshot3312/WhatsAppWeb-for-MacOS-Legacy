import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var webViewStore = WebViewStore()
    
    var body: some View {
        WhatsAppWebView(webViewStore: webViewStore)
            .frame(minWidth: 800, minHeight: 600)
            .edgesIgnoringSafeArea(.all)
            // Se quiser que a área colorida do WhatsApp suba até os botões da janela:
            .background(Color(NSColor.windowBackgroundColor))
    }
}
