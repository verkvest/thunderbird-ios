// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Bolt
import Core
import SwiftUI

struct AccountEditView: View {
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
    @State private var jmapServer: Server = Server(.jmap)
    @State private var imapServer: Server = Server(.imap)
    @State private var smtpServer: Server = Server(.smtp)
    @State private var emailProtocol: Account.EmailProtocol = .imap
    @State private var emailAddressLabel: String = ""
    @State private var emailAddressValue: String = ""
    @State private var name: String = ""
    @State private var isTesting: Bool = false

    @State private var error: Error? = nil {
        didSet { accountManager.error = error != nil ? AccountError(error!) : nil }
    }

    private func save() {
        accountManager.set(account)
        isPresented = false
    }

    private func test() {
        isTesting = true
    }

    // MARK: View
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacing()) {
                TextField("", text: $name)
                    .formInput("account_server_settings_name_label")
                    .autoFormattingDisabled()
                TextField("your.email@example.com", text: $emailAddressValue)
                    .formInput("account_server_settings_email_value_label")
                    .autoFormattingDisabled()
                TextField("Pat Example", text: $emailAddressLabel)
                    .formInput("account_server_settings_email_label_label")
                    .autoFormattingDisabled()
                VStack(spacing: .spacing()) {
                    EmailProtocolPicker($emailProtocol)
                    switch emailProtocol {
                    case .imap:
                        ServerEditView($imapServer)
                        ServerEditView($smtpServer)
                    case .jmap:
                        ServerEditView($jmapServer)
                    }
                }
                .padding(.top, density: .compact)
                .padding(.horizontal, density: .compact)
                .padding(.bottom, density: .default)
                .background {
                    RoundedRectangle(cornerRadius: 24.0)
                        .stroke(.gray.opacity(0.5))
                }
                .padding(.top, density: .compact)
                AuthorizationView($account, error: $error)
                    .padding(.vertical, density: .compact)
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
        .navigationTitle("edit_account_header")
        .toolbar {
            AccountTestButton { test() }
            AccountSaveButton { save() }
                .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $isTesting) {
            AccountTestView(account)
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            jmapServer = account.server(.jmap) ?? Server(.jmap)
            imapServer = account.server(.imap) ?? Server(.imap)
            smtpServer = account.server(.smtp) ?? Server(.smtp)
            emailProtocol = account.emailProtocol
            emailAddressLabel = account.emailAddress?.label ?? ""
            emailAddressValue = account.emailAddress?.value ?? ""
            name = !account.name.isEmpty ? account.name : emailAddressValue
        }
        .onChange(of: jmapServer) {
            account.servers = [
                jmapServer
            ]
        }
        .onChange(of: imapServer) {
            account.servers = [
                imapServer,
                smtpServer
            ]
        }
        .onChange(of: smtpServer) {
            account.servers = [
                imapServer,
                smtpServer
            ]
        }
        .onChange(of: emailAddressLabel) {
            account.identities = [
                EmailAddress(emailAddressValue, label: emailAddressLabel)
            ]
        }
        .onChange(of: emailAddressValue) {
            account.identities = [
                EmailAddress(emailAddressValue, label: emailAddressLabel)
            ]
        }
        .onChange(of: name) {
            account.name = name
        }
    }
}

#Preview("Account Edit View") {
    @Previewable @State var accountManager: AccountManager = AccountManager()
    @Previewable @State var account: Account = Account("Pat Example <example@gmail.com>")
    @Previewable @State var path: NavigationPath = NavigationPath()

    NavigationStack(path: $path) {
        AccountEditView($account, path: $path)
            .environment(accountManager)
    }
}

struct EmailProtocolPicker: View {
    init(_ emailProtocol: Binding<Account.EmailProtocol>) {
        _emailProtocol = emailProtocol
    }

    @Binding private var emailProtocol: Account.EmailProtocol

    // MARK: View
    var body: some View {
        Picker("account_server_settings_protocol_type_label", selection: $emailProtocol) {
            ForEach(Account.EmailProtocol.allCases, id: \.self) {
                Text($0.description)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview("Email Protocol Picker") {
    @Previewable @State var emailProtocol: Account.EmailProtocol = .imap

    EmailProtocolPicker($emailProtocol)
        .padding()
}

struct ServerEditView: View {
    init(_ server: Binding<Server>) {
        _server = server
    }

    @Binding private var server: Server

    private var label: LocalizedStringKey {
        switch server.serverProtocol {
        case .imap: "account_incoming_server_label"
        case .smtp: "account_outgoing_server_label"
        default: "account_server_settings_server_label"
        }
    }

    // MARK: View
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing(.compact)) {
            Text(label)
                .font(.headline)
            HStack {
                TextField(server.titleKey, text: $server.hostname)
                    .formInput("account_server_settings_host_label")
                    .autoFormattingDisabled()
                Spacer()
                TextField("\(server.serverProtocol.defaultPort)", value: $server.port, format: .number)
                    .multilineTextAlignment(.center)
                    .formInput("account_server_settings_port_label")
                    .autoFormattingDisabled()
                    .frame(maxWidth: 72.0)
            }
            ConnectionSecurityView($server.connectionSecurity)
        }
    }
}

#Preview("Server Edit View") {
    @Previewable @State var server: Server = Server(.imap, connectionSecurity: .tls, hostname: "imap.example.com")

    ServerEditView($server)
        .onChange(of: server, initial: true) {
            print(server)
        }
        .padding()
}

private extension Server {
    var titleKey: String {
        "\(serverProtocol.description.lowercased()).example.com"
    }
}

struct ConnectionSecurityView: View {
    init(_ connectionSecurity: Binding<Server.ConnectionSecurity>) {
        _connectionSecurity = connectionSecurity
    }

    @Binding private var connectionSecurity: Server.ConnectionSecurity

    // MARK: View
    var body: some View {
        Picker("account_server_settings_security_label", selection: $connectionSecurity) {
            ForEach(Server.ConnectionSecurity.allCases, id: \.self) {
                Text($0.description.capitalized(.sentence))
            }
        }
        .formInput("account_server_settings_security_label", layout: .horizontal)
    }
}

#Preview("Connection Security View") {
    @Previewable @State var connectionSecurity: Server.ConnectionSecurity = .tls

    ConnectionSecurityView($connectionSecurity)
        .onChange(of: connectionSecurity, initial: true) {
            print(connectionSecurity)
        }
        .padding()
}
