// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration
import EmailAddress
import Foundation
import IMAP
import MIME
import SMTP

extension Account {
    /// Refresh an expired OAuth token into the keychain. Password accounts are returned unchanged.
    public func renewedAuthorization() async throws -> Authorization {
        guard authenticationType == .oAuth2, authorization.isExpired, let refreshToken: String = authorization.refreshToken, let user: String = emailAddress?.value else {
            return authorization
        }
        guard let authConfig: OAuth2.Configuration = try await authConfig else {
            throw URLError(.unsupportedURL)
        }
        let data: Data = try await URLSession.shared.data(for: try .refreshToken(authConfig, refreshToken: refreshToken)).0
        let response: RefreshTokenResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
        let token: Token = .bearer(response.accessToken, Date(timeIntervalSinceNow: TimeInterval(response.expiresIn)))
        return .oauth(user: user, token: token, refresh: .refresh(refreshToken))
    }

    /// ISPDB lists OAuth first for mail.ru even though this app has no mail.ru client. Use a password there.
    public mutating func preferPasswordWhenOAuthUnavailable() async {
        guard authenticationType == .oAuth2 else { return }
        let configuration: OAuth2.Configuration? = try? await authConfig
        if configuration == nil {
            authenticationType = .password
        }
    }

    public func email(_ email: Email, in mailbox: String) async throws -> Email {
        let client: IMAPClient = try await imapClient
        try await client.select(mailbox: IMAP.Mailbox.Name(mailbox))
        return try await self.email(email)
    }

    public func mailboxes() async throws -> [Mailbox] {
        switch emailProtocol {
        case .imap:
            let client: IMAPClient = try await imapClient
            return try await client.list().map { Mailbox($0) }
        case .jmap:
            throw AccountError.emailAddressNotSupported
        }
    }

    public func setSeen(_ seen: Bool, uid: UID) async throws {
        let client: IMAPClient = try await imapClient
        try await client.changeFlags([.seen], uid: uid, add: seen)
    }

    public func setFlagged(_ flagged: Bool, uid: UID) async throws {
        let client: IMAPClient = try await imapClient
        try await client.changeFlags([.flagged], uid: uid, add: flagged)
    }

    public func move(uid: UID, to mailbox: String) async throws {
        let client: IMAPClient = try await imapClient
        try await client.move(uid: uid, to: IMAP.Mailbox.Name(mailbox))
    }

    public func unseenCount(mailbox: String = "INBOX") async throws -> Int {
        let client: IMAPClient = try await imapClient
        let status: IMAP.Mailbox.Status = try await client.status(mailbox: IMAP.Mailbox.Name(mailbox))
        let count: Int = status.unseenCount ?? 0
        if client.isIdling { try? await client.done() }
        try? client.disconnect()
        dropCachedClient()
        return count
    }

    public func watch(mailbox: String = "INBOX") async throws -> AsyncStream<IdleEvent> {
        let client: IMAPClient = try await imapClient
        try await client.select(mailbox: IMAP.Mailbox.Name(mailbox))
        return try await client.idle()
    }

    public func stopWatching() async {
        guard let client: IMAPClient = cachedIMAPClient(), client.isIdling else { return }
        try? await client.done()
    }

    public func send(to: [String], cc: [String] = [], bcc: [String] = [], subject: String, body: String, html: Bool) async throws {
        guard let outgoingServer, let sender: EmailAddress = emailAddress else {
            throw AccountError.emailAddressNotFound
        }
        let authorization: Authorization = try await renewedAuthorization()
        var copy: Self = self
        if authorization != self.authorization {
            copy.authorization = authorization
        }
        let message: SMTP.Email = SMTP.Email(
            sender: sender,
            recipients: to.map { EmailAddress($0) },
            copied: cc.map { EmailAddress($0) },
            blindCopied: bcc.map { EmailAddress($0) },
            subject: subject,
            body: try Body(part: Part(data: Data(body.utf8), contentType: .text(html ? "html" : "plain", .utf8)))
        )
        let client: SMTPClient = SMTPClient(try SMTP.Server(outgoingServer, authorization: copy.authorization))
        try await client.send(message)
        guard !MailboxDirectory.providerSavesSent(host: outgoingServer.hostname) else { return }
        let names: [String] = (try? await mailboxes().map(\.name)) ?? []
        guard let sent: String = MailboxDirectory.sent(in: names) else { return }
        try await imapClient.append(message.messageData, to: IMAP.Mailbox.Name(sent))
    }

    public func cachedHeader(in mailbox: String) -> (Email) -> MailCache.Header {
        let accountID: UUID = id
        let accountName: String = name
        return { email in
            MailCache.Header(
                id: "\(accountID.uuidString)|\(mailbox)|\(email.uid?.rawValue ?? 0)|\(email.id)",
                accountID: accountID,
                accountName: accountName,
                mailbox: mailbox,
                uid: email.uid?.rawValue,
                sequence: email.sequence ?? 0,
                subject: email.subject ?? "",
                from: email.sender.first?.addresses.first?.description ?? email.from.first?.addresses.first?.description ?? "",
                date: email.sent ?? email.received,
                unread: !email.flags.contains(.seen),
                flagged: email.flags.contains(.flagged),
                preview: String((email.body?.text ?? email.body?.preview ?? "").prefix(140))
            )
        }
    }
}
