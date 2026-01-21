import Foundation
import Intents
import UserNotifications

// MARK: - Focus Mode Service

/// Manages Focus Mode integration for Bay Navigator
/// Key use cases:
/// - Crisis notifications should ALWAYS break through (988, domestic violence, etc.)
/// - Deadline reminders for benefits should be time-sensitive
/// - Daily tips can respect Focus Mode (non-urgent)
@Observable
class FocusModeService {
    static let shared = FocusModeService()

    // Current focus status
    var currentFocusStatus: INFocusStatus?

    init() {
        // Request focus status authorization
        requestFocusStatusAuthorization()
    }

    // MARK: - Authorization

    private func requestFocusStatusAuthorization() {
        INFocusStatusCenter.default.requestAuthorization { status in
            // Status indicates whether we can read focus state
            // We don't need to read it - we just need to configure
            // our notifications correctly
        }
    }

    // MARK: - Notification Configuration

    /// Configure a notification to break through Focus Mode
    /// Use for: Crisis resources, imminent deadlines, urgent status changes
    func configureAsCritical(_ content: UNMutableNotificationContent) {
        content.interruptionLevel = .critical
        content.relevanceScore = 1.0
    }

    /// Configure a notification as time-sensitive
    /// Use for: Deadline reminders, application status updates
    func configureAsTimeSensitive(_ content: UNMutableNotificationContent) {
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 0.8
    }

    /// Configure a notification as normal (respects Focus Mode)
    /// Use for: Daily tips, new program announcements
    func configureAsNormal(_ content: UNMutableNotificationContent) {
        content.interruptionLevel = .active
        content.relevanceScore = 0.5
    }

    /// Configure a notification as passive (silent, respects Focus Mode)
    /// Use for: Sync complete, background updates
    func configureAsPassive(_ content: UNMutableNotificationContent) {
        content.interruptionLevel = .passive
        content.relevanceScore = 0.2
    }
}

// MARK: - Enhanced Notification Service Extension

extension NotificationService {

    // MARK: - Crisis Notifications (Critical - Always Break Through)

    /// Send crisis resource notification - ALWAYS breaks through Focus Mode
    func notifyCrisisResource(
        resourceName: String,
        phoneNumber: String
    ) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Crisis Support Available"
        content.body = "\(resourceName): \(phoneNumber)"
        content.sound = .defaultCritical
        content.categoryIdentifier = NotificationCategory.crisis.rawValue
        content.userInfo = [
            "type": "crisis",
            "phone": phoneNumber
        ]

        // Critical - breaks through ALL Focus Modes
        FocusModeService.shared.configureAsCritical(content)

        let request = UNNotificationRequest(
            identifier: "crisis-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    // MARK: - Deadline Notifications (Time-Sensitive)

    /// Schedule deadline reminder - breaks through Focus Mode as time-sensitive
    func scheduleUrgentDeadlineReminder(
        programId: String,
        programName: String,
        deadline: Date,
        hoursRemaining: Int
    ) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Deadline Today!"
        content.body = "\(programName) application due in \(hoursRemaining) hours"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.urgentDeadline.rawValue
        content.userInfo = [
            "programId": programId,
            "type": "urgentDeadline"
        ]

        // Time-sensitive - breaks through most Focus Modes
        FocusModeService.shared.configureAsTimeSensitive(content)

        let request = UNNotificationRequest(
            identifier: "urgent-deadline-\(programId)",
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    /// Schedule application status change - time-sensitive if action required
    func notifyStatusChangeWithPriority(
        programId: String,
        programName: String,
        newStatus: String,
        requiresAction: Bool
    ) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = requiresAction ? "Action Required" : "Application Update"
        content.body = "\(programName): \(newStatus)"
        content.sound = .default
        content.categoryIdentifier = requiresAction
            ? NotificationCategory.actionRequired.rawValue
            : NotificationCategory.statusUpdate.rawValue
        content.userInfo = [
            "programId": programId,
            "type": "statusChange",
            "status": newStatus
        ]

        // Time-sensitive if action required, normal otherwise
        if requiresAction {
            FocusModeService.shared.configureAsTimeSensitive(content)
        } else {
            FocusModeService.shared.configureAsNormal(content)
        }

        let request = UNNotificationRequest(
            identifier: "status-\(programId)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    // MARK: - Normal Notifications (Respect Focus Mode)

    /// Daily tip - respects Focus Mode completely
    func scheduleDailyTipRespectingFocus(hour: Int = 10, minute: Int = 0) {
        guard isAuthorized else { return }

        let tips = [
            "Did you know? CalFresh benefits can help families buy nutritious food.",
            "Tip: Many programs accept applications online 24/7.",
            "Remember to keep copies of all documents you submit.",
            "Tip: You may qualify for multiple programs. Don't limit yourself!",
            "Check program deadlines regularly to avoid missing opportunities.",
            "Tip: Case workers can help you navigate the application process.",
            "Many programs offer assistance in multiple languages."
        ]

        let content = UNMutableNotificationContent()
        content.title = "Bay Navigator Tip"
        content.body = tips.randomElement()!
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.dailyTip.rawValue

        // Normal priority - respects Focus Mode
        FocusModeService.shared.configureAsNormal(content)

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "dailytip",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Passive Notifications (Silent)

    /// Sync complete - passive, won't interrupt
    func notifySyncComplete(itemCount: Int) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Sync Complete"
        content.body = "\(itemCount) items synced across devices"
        content.categoryIdentifier = NotificationCategory.sync.rawValue

        // Passive - silent, won't interrupt
        FocusModeService.shared.configureAsPassive(content)

        let request = UNNotificationRequest(
            identifier: "sync-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        center.add(request)
    }
}

// MARK: - Additional Notification Categories

extension NotificationCategory {
    static let crisis = NotificationCategory(rawValue: "CRISIS")!
    static let urgentDeadline = NotificationCategory(rawValue: "URGENT_DEADLINE")!
    static let sync = NotificationCategory(rawValue: "SYNC")!
}

// MARK: - Focus Mode Settings View

import SwiftUI

struct FocusModeSettingsView: View {
    @AppStorage("crisisBreakThrough") private var crisisBreakThrough = true
    @AppStorage("deadlineBreakThrough") private var deadlineBreakThrough = true
    @AppStorage("statusBreakThrough") private var statusBreakThrough = false

    var body: some View {
        Form {
            Section {
                Text("Control which notifications can break through Focus Mode (Do Not Disturb, Sleep, etc.)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(isOn: $crisisBreakThrough) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Crisis Resources")
                        Text("988 Suicide Prevention, domestic violence hotlines")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.red)
            } header: {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Critical")
                }
            } footer: {
                Text("Recommended: Always on. These notifications only appear when you access crisis resources.")
            }

            Section {
                Toggle(isOn: $deadlineBreakThrough) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Deadline Reminders")
                        Text("Benefits application deadlines")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.orange)

                Toggle(isOn: $statusBreakThrough) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Action Required")
                        Text("When your application needs additional information")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.orange)
            } header: {
                HStack {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .foregroundStyle(.orange)
                    Text("Time-Sensitive")
                }
            } footer: {
                Text("These notifications appear on your lock screen during Focus Mode but won't make sound.")
            }

            Section {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Daily tips and general updates respect your Focus Mode settings.")
                        .font(.subheadline)
                }
            } header: {
                Text("Other Notifications")
            }
        }
        .navigationTitle("Focus Mode")
    }
}

// MARK: - Crisis Detection Integration

extension FocusModeService {

    /// Check if current notification should break through based on content
    func shouldBreakThrough(for notificationType: String) -> Bool {
        switch notificationType {
        case "crisis":
            return UserDefaults.standard.bool(forKey: "crisisBreakThrough")
        case "urgentDeadline":
            return UserDefaults.standard.bool(forKey: "deadlineBreakThrough")
        case "actionRequired":
            return UserDefaults.standard.bool(forKey: "statusBreakThrough")
        default:
            return false
        }
    }
}
