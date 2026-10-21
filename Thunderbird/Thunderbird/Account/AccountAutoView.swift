// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Bolt
import Core
import SwiftUI

struct AccountAutoView: View {
    init(
        _ account: Binding<Account>,
        path: Binding<NavigationPath> = .constant(NavigationPath()),
        isPresented: Binding<Bool> = .constant(false)
    ) {
        _isPresented = isPresented
        _account = account
        _path = path
    }

    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Binding private var isPresented: Bool
    @Binding private var account: Account
    @Binding private var path: NavigationPath
    @State private var jmapAccount: Account? = nil
    @State private var isRefreshing: Bool = false
    @State private var isJMAPSelected: Bool = false
    @State private var isAutoSelected: Bool = true
    @State private var isTesting: Bool = false
    @State private var error: Error? = nil {
        didSet { accountManager.error = error != nil ? AccountError(error!) : nil }
    }

    private var selectedAccount: Account {
        if isJMAPSelected, let jmapAccount {
            return jmapAccount
        }
        return account
    }

    private func refresh() async {
        accountManager.error = nil
        isRefreshing = true
        do {
            jmapAccount = try? await account.jmapConfigured()
            account = try await account.autoconfigured()
        } catch {
            accountManager.error = AccountError(error) ?? .autoconfig(error)
        }
        isRefreshing = false
    }

    private func save() {
        accountManager.set(selectedAccount)
        isPresented = false
    }

    private func test() {
        isTesting = true
    }

    // MARK: View
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacing()) {
                Text(account.emailAddress?.description ?? "")
                    .bold()
                if let jmapAccount {
                    Toggle(isOn: $isJMAPSelected) {
                        ConfigurationView(jmapAccount) {
                            self.account = jmapAccount
                            path.append(AccountDestination.edit)
                        }
                    }
                    .fullToggleStyle()
                    .onChange(of: isJMAPSelected) {
                        isAutoSelected = !isJMAPSelected
                    }
                }
                Toggle(isOn: $isAutoSelected) {
                    ConfigurationView(account) {
                        path.append(AccountDestination.edit)
                    }
                }
                .fullToggleStyle()
                .onChange(of: isAutoSelected) {
                    isJMAPSelected = !isAutoSelected
                }
                AuthorizationView($account, error: $error)
                    .padding(.vertical, density: .compact)
                    .onChange(of: account.authenticationType) {
                        jmapAccount?.authenticationType = account.authenticationType
                    }
                Divider()
                HStack {
                    Spacer()
                    AccountTestButton { test() }
                        .buttonStyle(.bordered)
                    AccountSaveButton { save() }
                        .buttonStyle(.borderedProminent)
                        .labelStyle(.titleOnly)
                }
            }
            .padding(density: .default)
        }
        .navigationTitle("auto_account_header")
        .toolbar {
            AccountTestButton { test() }
            AccountSaveButton { save() }
                .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $isTesting) {
            AccountTestView(selectedAccount)
                .presentationDragIndicator(.visible)
        }
        .refreshable(action: {
            await refresh()
        })
        .task {
            await refresh()
        }
    }
}

#Preview("Account Auto View") {
    @Previewable @State var accountManager: AccountManager = AccountManager()
    @Previewable @State var account: Account = Account("Pat Example <example@fastmail.com>")
    @Previewable @State var path: NavigationPath = NavigationPath()

    NavigationStack(path: $path) {
        AccountAutoView($account, path: $path)
            .environment(accountManager)
    }
}

struct ConfigurationView: View {
    let account: Account

    init(_ account: Account, action: @escaping @MainActor () -> Void = {}) {
        self.account = account
        self.action = action
    }

    private let action: () -> Void

    // MARK: View
    var body: some View {
        VStack(alignment: .leading) {
            Text(account.emailProtocol.titleKey)
                .font(.headline)
            ForEach(account.servers) { server in
                Text("\(server.hostname):\(server.port)")
                    .font(.subheadline)
                    .monospaced()
            }
            Text(account.servers.first?.connectionSecurity.description ?? "")
                .font(.subheadline)
            Button(action: action) {
                Text("account_server_edit_configuration")
                    .font(.caption)
            }
            .padding(.top, density: .compact)
        }
    }
}

#Preview("Configuration View") {
    @Previewable @State var account: Account = Account("example@thunderbird.net")

    ConfigurationView(account)
        .padding()
}

private extension Account.EmailProtocol {
    var titleKey: LocalizedStringKey {
        switch self {
        case .imap: "imap"
        case .jmap: "jmap"
        }
    }
}
