// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(\.openURL) private var openURL: OpenURLAction
    @AppStorage("verkvest.faceIDLock") private var faceIDLock: Bool = false
    @AppStorage("verkvest.backgroundRefresh") private var backgroundRefresh: Bool = true

    var body: some View {
        NavigationStack {
            List {
                Section("phone_section") {
                    Toggle("face_id_toggle", isOn: $faceIDLock)
                        .font(.body)
                    Toggle("background_refresh_toggle", isOn: $backgroundRefresh)
                        .font(.body)
                        .onChange(of: backgroundRefresh) {
                            #if os(iOS)
                            if backgroundRefresh {
                                MailRefresh.requestNotificationPermission()
                                MailRefresh.schedule()
                            }
                            #endif
                        }
                    Text("idle_foreground_only")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("accounts_heading") {
                    ForEach(accountManager.allAccounts) { account in
                        HStack {
                            Text(account.name)
                            Spacer()
                            Menu {
                                Button(action: {
                                    accountManager.delete(account)
                                }) {
                                    Text("account_sign_out_button")
                                }
                            } label: {
                                Label("options_button", systemImage: "ellipsis")
                                    .labelStyle(.iconOnly)
                                    .foregroundStyle(.primary)
                            }.compositingGroup()

                        }
                    }
                    NavigationLink(destination: {
                        ManualAccount()
                    }) {
                        Label("add_account_header", systemImage: "plus")
                    }.navigationLinkIndicatorVisibility(.hidden)
                }
                Section("Miscellaneous") {
                    NavigationLink("Feature Flags", destination: FeatureFlagDebugView())
                    Button(
                        "donation_support",
                        action: {
                            guard let url = URL(string: "https://www.thunderbird.net/en-US/donate/") else { return }
                            openURL(url)
                        })
                }
            }
        }.navigationTitle("settings_header")
    }
}
