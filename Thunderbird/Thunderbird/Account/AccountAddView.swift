// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Bolt
import Core
import SwiftUI

struct AccountAddView: View {
    init(
        _ account: Binding<Account>,
        path: Binding<NavigationPath> = .constant(NavigationPath()),
        autofocus: Bool = false
    ) {
        _account = account
        _path = path
        self.autofocus = autofocus
    }

    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Binding private var account: Account
    @Binding private var path: NavigationPath
    @State private var valueText: String = ""
    @State private var labelText: String = ""
    @FocusState private var isValueFocused: Bool
    @FocusState private var isLabelFocused: Bool
    @State private var isSearching: Bool = false
    private let autofocus: Bool

    private var isDisabled: Bool { !valueText.isEmailAddress || isSearching }

    private func refreshEmailAddress() {
        account.identities = [
            EmailAddress(valueText, label: labelText)
        ]
    }

    private func autoconfigure() async {
        accountManager.error = nil
        isSearching = true
        do {
            account = try await account.autoconfigured()
            path.append(AccountDestination.auto)
        } catch {
            accountManager.error = AccountError(error) ?? .autoconfig(error)
        }
        isSearching = false
    }

    // MARK: View
    var body: some View {
        VStack(spacing: .spacing()) {
            Spacer()
            TextField("your.email@example.com", text: $valueText)
                .formInput("account_server_settings_email_value_label", isRequired: true)
                .autoFormattingDisabled()
                #if os(iOS)
            .keyboardType(.emailAddress)
            .submitLabel(.continue)
                #endif
                .focused($isValueFocused, equals: true)
                .onSubmit {
                    isLabelFocused = true
                }
            TextField("Pat Example", text: $labelText)
                .formInput("account_server_settings_email_label_label")
                .autoFormattingDisabled()
                #if os(iOS)
            .submitLabel(.continue)
                #endif
                .focused($isLabelFocused, equals: true)
                .onSubmit {
                    Task { await autoconfigure() }
                }
            HStack {
                Spacer()
                Button(action: {
                    Task { await autoconfigure() }
                }) {
                    Text("next_button")
                        .padding(.horizontal, density: .compact)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isDisabled)
            }
            Spacer()
            Spacer()
            Button(action: {
                path.append(AccountDestination.edit)
            }) {
                Text("account_server_manual_configuration")
            }
        }
        .navigationTitle("add_account_header")
        .onChange(of: valueText) {
            refreshEmailAddress()
        }
        .onChange(of: labelText) {
            refreshEmailAddress()
        }
        .onAppear {
            valueText = account.emailAddress?.value ?? ""
            labelText = account.emailAddress?.label ?? ""
            isValueFocused = autofocus
        }
        .padding(density: .default)
    }
}

#Preview("Account Add View") {
    @Previewable @State var accountManager: AccountManager = AccountManager()
    @Previewable @State var account: Account = Account("Pat Example <example@thunderbird.net>")
    @Previewable @State var path: NavigationPath = NavigationPath()

    NavigationStack(path: $path) {
        AccountAddView($account, path: $path)
            .environment(accountManager)
    }
}
