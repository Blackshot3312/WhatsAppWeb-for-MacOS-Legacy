import AppKit
import Foundation
import UserNotifications

class NotificationManager {
    private var lastNotificationCount = 0
    
    func showNotification(messageCount: Int) {
        guard messageCount > lastNotificationCount,
                 messageCount - lastNotificationCount <= 5
           else { return }
        
        
        let content = UNMutableNotificationContent()
        content.title = "WhatsApp"
        
        let newMessages = messageCount - lastNotificationCount
        if newMessages == 1 {
            content.body = "Você tem 1 nova mensagem"
        } else {
            content.body = "Você tem \(newMessages) novas mensagens"
        }
        
        content.sound = .default
        content.badge = NSNumber(value: messageCount)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erro ao mostrar notificação: \(error.localizedDescription)")
            }
        }
        
        lastNotificationCount = messageCount
        NSApplication.shared.requestUserAttention(.criticalRequest)
        NSApplication.shared.dockTile.badgeLabel = "\(messageCount)"
    }
    
    func clearBadge() {
     lastNotificationCount = 0
        NSApplication.shared.dockTile.badgeLabel = nil
    }
}
