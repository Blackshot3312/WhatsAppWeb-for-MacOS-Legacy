
import SwiftUI

@main
struct WhatsappApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        //.windowStyle(.hiddenTitleBar)
    }
}
