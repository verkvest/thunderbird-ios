// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

@main
struct App: SwiftUI.App {
    init() {
        OAuth2.configurations = OAuth2.Configuration.allCases
    }

    @State private var accountManager: AccountManager = AccountManager()
    @State private var mailboxManager: UnifiedMailboxManager = UnifiedMailboxManager()
    @State private var featureFlags: FeatureFlags = FeatureFlags(distribution: .current)
    @State private var showAlert = false

    // MARK: App
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(accountManager)
                    .environment(mailboxManager)
                    .environment(featureFlags)
                if showAlert {
                    FeatureNotImplementedView()
                }
            }
        }.onChange(of: AlertManager.shared.showAlert) {
            showAlert = AlertManager.shared.showAlert
        }
        #if os(macOS)
        .defaultSize(width: 768.0, height: 512.0)
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
