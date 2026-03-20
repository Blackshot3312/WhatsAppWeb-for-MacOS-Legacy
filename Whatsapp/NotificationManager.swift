import AppKit
import Foundation
import UserNotifications

class NotificationManager {
    private var lastNotificationCount = 0
    
    func showImmediateNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default // Aqui você pode trocar pelo seu som customizado
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
        NSApplication.shared.requestUserAttention(.informationalRequest)
    }
    
    func showNotification(messageCount: Int) {
        // Evita notificações duplicadas ou disparos falsos
        guard messageCount > lastNotificationCount else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "WhatsApp"
        
        let newMessages = messageCount - lastNotificationCount
        content.body = newMessages == 1 ? "Você tem 1 nova mensagem" : "Você tem \(newMessages) novas mensagens"
        
        // No macOS 11, use .default ou o nome do seu arquivo local
        content.sound = .default
        content.badge = NSNumber(value: messageCount)
        
        // Identificador fixo para não empilhar dezenas de banners
        let request = UNNotificationRequest(
            identifier: "whatsapp-web-notification",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erro: \(error.localizedDescription)")
            }
        }
        
        lastNotificationCount = messageCount
        
        // Faz o ícone do Dock pular no Big Sur
        NSApplication.shared.requestUserAttention(.informationalRequest)
    }
    
    func clearBadge() {
        lastNotificationCount = 0
        NSApplication.shared.dockTile.badgeLabel = nil
        // Limpa as notificações do Centro de Notificações
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
