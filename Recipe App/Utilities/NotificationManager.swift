import Foundation
import UserNotifications
import UIKit

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized: Bool = false
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Check current notification authorization status
    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Request notification permission from the user
    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion?(granted)
                
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Open the system settings page for the app (for re-enabling after denial)
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Meal Plan Reminders
    
    /// Schedule a reminder for a meal plan entry
    /// Fires 30 minutes before the meal time (morning/noon/evening based on meal type)
    func scheduleMealPlanReminder(recipeTitle: String, date: Date, mealType: MealPlanEntry.MealType, entryID: UUID) {
        guard AppSettings.shared.enableNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = mealTypeEmoji(mealType) + " Time to cook!"
        content.body = "\(recipeTitle) is on your \(mealType.rawValue.lowercased()) plan today."
        content.sound = .default
        content.categoryIdentifier = "MEAL_REMINDER"
        
        // Set reminder time based on meal type
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        switch mealType {
        case .breakfast: components.hour = 7;  components.minute = 30
        case .lunch:     components.hour = 11; components.minute = 30
        case .dinner:    components.hour = 17; components.minute = 0
        case .snack:     components.hour = 14; components.minute = 30
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "mealplan-\(entryID.uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule meal reminder: \(error.localizedDescription)")
            }
        }
    }
    
    /// Remove a meal plan reminder when the entry is deleted
    func removeMealPlanReminder(entryID: UUID) {
        center.removePendingNotificationRequests(
            withIdentifiers: ["mealplan-\(entryID.uuidString)"]
        )
    }
    
    // MARK: - Daily Meal Suggestion
    
    /// Schedule a daily notification suggesting what to cook
    /// Fires at 4:30 PM each day to help with "what's for dinner" planning
    func scheduleDailySuggestion(enabled: Bool) {
        // Always remove existing one first
        center.removePendingNotificationRequests(withIdentifiers: ["daily-suggestion"])
        
        guard enabled && AppSettings.shared.enableNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🍽 What's for dinner?"
        content.body = "Open Recipe Box for a personalized meal suggestion."
        content.sound = .default
        content.categoryIdentifier = "DAILY_SUGGESTION"
        
        var components = DateComponents()
        components.hour = 16
        components.minute = 30
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-suggestion",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule daily suggestion: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Cooking Timer Notification
    
    /// Schedule a notification for when a cooking timer finishes
    /// This fires even if the app is in the background
    func scheduleTimerNotification(stepText: String, seconds: Int, timerID: String = UUID().uuidString) {
        guard AppSettings.shared.enableNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⏱ Timer Done!"
        content.body = stepText
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = "TIMER_DONE"
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(max(seconds, 1)),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "timer-\(timerID)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule timer notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Cancel a specific timer notification
    func cancelTimerNotification(timerID: String) {
        center.removePendingNotificationRequests(
            withIdentifiers: ["timer-\(timerID)"]
        )
    }
    
    // MARK: - Weekly Meal Prep Reminder
    
    /// Schedule a weekly reminder to plan meals (Sunday at 9 AM by default)
    func scheduleWeeklyPlanReminder(enabled: Bool) {
        center.removePendingNotificationRequests(withIdentifiers: ["weekly-plan"])
        
        guard enabled && AppSettings.shared.enableNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📋 Plan Your Week"
        content.body = "Take a minute to plan your meals for the week ahead."
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_PLAN"
        
        var components = DateComponents()
        components.weekday = 1  // Sunday
        components.hour = 9
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly-plan",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule weekly plan reminder: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Master Toggle
    
    /// Called when the user toggles notifications on/off in settings
    func handleNotificationToggle(enabled: Bool) {
        if enabled {
            requestPermission { granted in
                if granted {
                    self.scheduleDailySuggestion(enabled: AppSettings.shared.enableDailySuggestionNotification)
                    self.scheduleWeeklyPlanReminder(enabled: AppSettings.shared.enableWeeklyPlanNotification)
                }
            }
        } else {
            // Remove all pending notifications
            center.removeAllPendingNotificationRequests()
        }
    }
    
    /// Reschedule recurring notifications (call after settings change)
    func refreshScheduledNotifications() {
        guard AppSettings.shared.enableNotifications else { return }
        scheduleDailySuggestion(enabled: AppSettings.shared.enableDailySuggestionNotification)
        scheduleWeeklyPlanReminder(enabled: AppSettings.shared.enableWeeklyPlanNotification)
    }
    
    // MARK: - Clear All
    
    /// Remove all pending and delivered notifications
    func clearAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
    
    // MARK: - Helpers
    
    private func mealTypeEmoji(_ type: MealPlanEntry.MealType) -> String {
        switch type {
        case .breakfast: return "🌅"
        case .lunch:     return "☀️"
        case .dinner:    return "🌙"
        case .snack:     return "🍿"
        }
    }
}
