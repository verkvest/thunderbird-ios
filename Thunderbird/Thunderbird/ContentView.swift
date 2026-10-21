// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

struct ContentView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(MailboxModel.self) private var mailbox: MailboxModel
    @Environment(AppLock.self) private var appLock: AppLock
    @Environment(\.scenePhase) private var scenePhase: ScenePhase
    @State private var isPresented: Bool = false

    // MARK: View
    var body: some View {
        ZStack {
            if accountManager.allAccounts.isEmpty {
                WelcomeScreen($isPresented)
            } else {
                EmailListView()
            }
            if appLock.isLocked && !accountManager.allAccounts.isEmpty {
                LockScreen()
            }
        }
        .sheet(isPresented: $isPresented) {
            AccountView(isPresented: $isPresented)
                .presentationDragIndicator(.visible)
        }
        .task {
            await accountManager.checkAndRenewExpirations()
            appLock.lockIfNeeded()
            #if os(iOS)
            MailRefresh.schedule()
            #endif
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                Task { await mailbox.restartIdle(accounts: accountManager.allAccounts, active: !appLock.isLocked) }
                #if os(iOS)
                MailRefresh.schedule()
                #endif
            default:
                Task { await mailbox.restartIdle(accounts: accountManager.allAccounts, active: false) }
                appLock.lockIfNeeded()
            }
        }
    }
}

#Preview("Content View") {
    @Previewable @State var accountManager: AccountManager = AccountManager()
    @Previewable @State var mailbox: MailboxModel = MailboxModel()
    @Previewable @State var appLock: AppLock = AppLock()

    ContentView()
        .environment(accountManager)
        .environment(mailbox)
        .environment(appLock)
}
