import Foundation
import UserNotifications
import SwiftData

@Observable
class NotificationManager {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        requestPermissions()
        scheduleDailyNotification()
    }
    
    private func requestPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleDailyNotification() {
        // Remove any existing notifications
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Create date components for 9 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        // Create the trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: "daily-care-check",
            content: createNotificationContent(),
            trigger: trigger
        )
        
        // Schedule the notification
        notificationCenter.add(request)
    }
    
    private func createNotificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
//        // Get plants that need care today
//        let descriptor = FetchDescriptor<Plant>()
//        guard let plants = try? modelContext.fetch(descriptor) else {
//            return content
//        }
//        
//        let calendar = Calendar.current
//        let today = calendar.startOfDay(for: Date())
//        
//        // Count tasks needed today
//        var wateringCount = 0
//        var rotationCount = 0
//        
//        for plant in plants {
//            let wateringDate = calendar.startOfDay(for: plant.nextWateringDate)
//            if today >= wateringDate {
//                wateringCount += 1
//            }
//            
//            if let nextRotation = plant.nextRotationDate {
//                let rotationDate = calendar.startOfDay(for: nextRotation)
//                if today >= rotationDate {
//                    rotationCount += 1
//                }
//            }
//        }
//        
//        let totalTasks = wateringCount + rotationCount
//        if totalTasks == 0 {
//            // No notification needed
//            content.body = ""
//            return content
//        }
//        
//        // Create notification message
//        content.title = "Plant Care Needed"
//		
//        if wateringCount > 0 && rotationCount > 0 {
//            content.body = "\(wateringCount) plants need water and \(rotationCount) need rotation today"
//        } else if wateringCount > 0 {
//            content.body = "\(wateringCount) plant\(wateringCount == 1 ? "" : "s") need\(wateringCount == 1 ? "s" : "") water today"
//        } else {
//            content.body = "\(rotationCount) plant\(rotationCount == 1 ? "" : "s") need\(rotationCount == 1 ? "s" : "") rotation today"
//        }
//        
//        content.sound = .default
        return content
    }
} 
