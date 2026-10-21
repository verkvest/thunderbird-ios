// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Foundation

#if os(iOS)
import BackgroundTasks
import UserNotifications

/// Short foreground-style IMAP check scheduled by the system. Does not use IDLE.
enum MailRefresh {
    static let id: String = "com.verkvest.thunderbird.refresh"
    private static let countsKey: String = "verkvest.unseenCounts"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: id, using: nil) { task in
            guard let task: BGAppRefreshTask = task as? BGAppRefreshTask else { return }
            let work: Task<Void, Never> = Task {
                await probe()
                task.setTaskCompleted(success: true)
                schedule()
            }
            task.expirationHandler = { work.cancel() }
        }
    }

    static func schedule() {
        guard UserDefaults.standard.object(forKey: "verkvest.backgroundRefresh") as? Bool ?? true else { return }
        guard !ProcessInfo.processInfo.isLowPowerModeEnabled else { return }
        let request: BGAppRefreshTaskRequest = BGAppRefreshTaskRequest(identifier: id)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    @MainActor
    private static func probe() async {
        let manager: AccountManager = AccountManager()
        var counts: [String: Int] = UserDefaults.standard.dictionary(forKey: countsKey) as? [String: Int] ?? [:]
        for account in manager.allAccounts {
            guard let unseen: Int = try? await account.unseenCount() else { continue }
            let key: String = account.id.uuidString
            let previous: Int = counts[key] ?? 0
            counts[key] = unseen
            if unseen > previous {
                await notify(account: account.name, count: unseen - previous)
            }
        }
        UserDefaults.standard.set(counts, forKey: countsKey)
    }

    @MainActor
    private static func notify(account: String, count: Int) async {
        let content: UNMutableNotificationContent = UNMutableNotificationContent()
        content.title = account
        content.body = String(format: NSLocalizedString("new_mail_notification", comment: ""), count)
        let request: UNNotificationRequest = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
#endif
