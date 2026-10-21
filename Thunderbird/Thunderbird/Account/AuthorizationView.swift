// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import AuthenticationServices
import Autoconfiguration
import BoltUI
import SwiftUI

struct AuthorizationView: View {
    init(_ account: Binding<Account>, error: Binding<Error?> = .constant(nil), isEditable: Bool = true) {
        self.isEditable = isEditable
        _account = account
        _error = error
    }

    @Binding private var account: Account
    @Binding private var error: Error?
    @State private var password: String = ""
    private let isEditable: Bool

    // MARK: View
    var body: some View {
        VStack(spacing: .spacing(.compact)) {
            if isEditable {
                AuthenticationTypeView($account.authenticationType)
            }
            switch account.authenticationType {
            case .oAuth2:
                OAuthButton($account, error: $error)
            case .password:
                PasswordField("account_server_settings_authentication_password_cleartext", text: $password)
                    .onChange(of: password) { account.password = password }
                    .onAppear { password = account.password }
            case .none:
                EmptyView()
            }
        }
    }
}

#Preview("Authorization View") {
    @Previewable @State var account: Account = .example
    @Previewable @State var error: Error?

    AuthorizationView($account, error: $error)
        .padding()
    Divider()
    AuthorizationView($account, error: $error, isEditable: false)
        .padding()
}

struct AuthenticationTypeView: View {
    init(_ authenticationType: Binding<AuthenticationType>) {
        _authenticationType = authenticationType
    }

    @Binding private var authenticationType: AuthenticationType

    // MARK: View
    var body: some View {
        Picker("account_server_settings_authentication_label", selection: $authenticationType) {
            ForEach(AuthenticationType.allCases, id: \.self) {
                Text($0.description.capitalized(.sentence))
            }
        }
        .formInput("account_server_settings_authentication_label", layout: .horizontal)
    }
}

#Preview("Authentication Type View") {
    @Previewable @State var authenticationType: AuthenticationType = .oAuth2

    AuthenticationTypeView($authenticationType)
        .onChange(of: authenticationType, initial: true) {
            print(authenticationType)
        }
        .padding()
}

private extension Account {
    static var example: Self {
        Account(
            identities: [
                "example@thunderbird.net"
            ],
            servers: [
                Server(.imap, authenticationType: .oAuth2)
            ]
        )
    }

    var password: String {
        set {
            guard let emailAddress else { return }
            authorization = .basic(user: emailAddress.value, password: newValue)
        }
        get {
            switch authorization {
            case .basic(_, let password): password
            default: ""
            }
        }
    }
}
