import Cocoa
import UserNotifications
import SwiftUI

class AppDelegate: NSObject,
                   NSApplicationDelegate,
                   UNUserNotificationCenterDelegate {

    var webViewStore: WebViewStore?

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // Sistema de notificações (inicial)
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if granted {
                print("Permissão de notificação concedida")
            } else if let error = error {
                print("Erro ao solicitar permissão: \(error.localizedDescription)")
            }
        }

        // Manu global
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

    @objc private func clearSession() {
        webViewStore?.clearCookiesAndReload()
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Mostrar notificações mesmo com app em foco
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // Clique na notificação
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        completionHandler()
    }
}
