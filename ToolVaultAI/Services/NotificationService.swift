import Combine
import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    @Published private(set) var isAuthorized = false
    @Published var errorMessage: String?

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func requestAuthorization() async {
        do {
            isAuthorized = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scheduleMaintenanceReminder(
        toolName: String,
        maintenanceType: MaintenanceType,
        date: Date,
        recurrence: MaintenanceRecurrence,
        identifier: String
    ) async {
        await refreshAuthorizationStatus()
        guard isAuthorized else {
            await requestAuthorization()
            guard isAuthorized else { return }
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Tool maintenance due"
        content.body = "\(maintenanceType.rawValue) for \(toolName)"
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .weekday], from: date)
        components.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: recurrence != .none)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
