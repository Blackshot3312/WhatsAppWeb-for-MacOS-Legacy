import Cocoa
import UserNotifications
import SwiftUI

class AppDelegate: NSObject,
                   NSApplicationDelegate,
                   UNUserNotificationCenterDelegate,
                   NSWindowDelegate{

    var webViewStore: WebViewStore?

    func applicationDidFinishLaunching(_ notification: Notification) {

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let firstWindow = NSApplication.shared.windows.first {
                firstWindow.delegate = self
                
                //firstWindow.titleVisibility = .hidden
                //firstWindow.titlebarAppearsTransparent = true
                //firstWindow.styleMask.insert(.fullSizeContentView)
            }
        }

        setupMenu()
    }
    // MARK: - Menu global

    private func setupMenu() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu(title: "Whatsapp")
        appMenuItem.submenu = appMenu
        
        let reopenWindowItem = NSMenuItem(
            title: "Abrir Janela do WhatsApp",
            action: #selector(reopenMainWindow),
            keyEquivalent: "o"
        )
        reopenWindowItem.keyEquivalentModifierMask = [.command]
        reopenWindowItem.target = self
        appMenu.addItem(reopenWindowItem)

        appMenu.addItem(NSMenuItem.separator())

        let clearSessionItem = NSMenuItem(
            title: "Limpar Sessão",
            action: #selector(clearSession),
            keyEquivalent: "r"
        )
        clearSessionItem.keyEquivalentModifierMask = [.command, .option]
        clearSessionItem.target = self

        appMenu.addItem(clearSessionItem)
        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "Sair",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenu.addItem(quitItem)
        
        
    }
    
    @objc private func reopenMainWindow() {
        NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    @objc private func clearSession() {
        webViewStore?.clearCookiesAndReload()
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    //Notification System
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        completionHandler()
    }
    

    // MARK: - Gerenciamento de Janela

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
