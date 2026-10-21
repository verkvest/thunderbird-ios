// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Foundation
import Testing

struct MailboxLoaderTests {
    @Test func unifiedInboxPagesNewestAcrossAccounts() async throws {
        let gmail: UUID = UUID()
        let mailru: UUID = UUID()
        let loader: MailboxLoader = MailboxLoader(
            sources: [
                FixtureSource(
                    accountID: gmail,
                    accountName: "Gmail",
                    rows: [
                        header(gmail, "Gmail", "g-old", sequence: 10, date: 100),
                        header(gmail, "Gmail", "g-new", sequence: 11, date: 300)
                    ]
                ),
                FixtureSource(
                    accountID: mailru,
                    accountName: "Mail.ru",
                    rows: [
                        header(mailru, "Mail.ru", "m-old", sequence: 1, date: 50),
                        header(mailru, "Mail.ru", "m-mid", sequence: 2, date: 200),
                        header(mailru, "Mail.ru", "m-new", sequence: 3, date: 400)
                    ]
                )
            ],
            pageSize: 2
        )
        let first: [MailHeader] = try await loader.load(accountID: nil, mailbox: "INBOX")
        #expect(first.map(\.subject) == ["m-new", "g-new"])
        let cursors: [UUID: Int] = Dictionary(uniqueKeysWithValues: first.map { ($0.accountID, $0.sequence) })
        let second: [MailHeader] = try await loader.load(accountID: nil, mailbox: "INBOX", olderThan: cursors)
        #expect(second.map(\.subject) == ["m-mid", "g-old"])
        let one: [MailHeader] = try await loader.load(accountID: mailru, mailbox: "INBOX")
        #expect(one.allSatisfy { $0.accountID == mailru })
        #expect(one.map(\.subject) == ["m-new", "m-mid"])
    }

    @Test func cacheRoundTripKeepsHeadersAndBodies() throws {
        let root: URL = FileManager.default.temporaryDirectory.appending(path: "mail-cache-\(UUID().uuidString)", directoryHint: .isDirectory)
        let store: MailCacheStore = MailCacheStore(root: root)
        let account: UUID = UUID()
        let header: MailCache.Header = MailCache.Header(
            id: "row-1",
            accountID: account,
            accountName: "Ada",
            mailbox: "INBOX",
            uid: 9,
            sequence: 9,
            subject: "Hello",
            from: "ada@example.com",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            unread: true,
            flagged: false,
            preview: "Preview"
        )
        try store.save(headers: [header], accountID: account, mailbox: "INBOX")
        #expect(store.headers(accountID: account, mailbox: "INBOX") == [header])
        let body: MailCache.Body = MailCache.Body(id: header.id, html: "<p>Hi</p>", text: "Hi", attachments: [MailCache.Attachment(filename: "note.txt", mime: "text/plain", data: Data("note".utf8))])
        try store.save(body: body)
        #expect(store.body(id: header.id) == body)
        var listing: String = ""
        let paths: [String] = (try? FileManager.default.subpathsOfDirectory(atPath: root.path())) ?? []
        for path in paths {
            if let text: String = try? String(contentsOf: root.appending(path: path), encoding: .utf8) {
                listing += text
            }
        }
        #expect(listing.contains("Hello"))
        #expect(!listing.lowercased().contains("password"))
        #expect(!listing.contains("ya29"))
    }

    @Test func sentAndArchiveNames() {
        let names: [String] = ["INBOX", "[Gmail]/Sent Mail", "Отправленные", "[Gmail]/All Mail", "Корзина", "Archive"]
        #expect(MailboxDirectory.sent(in: names) == "[Gmail]/Sent Mail")
        #expect(MailboxDirectory.archive(in: names) == "Archive")
        #expect(MailboxDirectory.trash(in: ["INBOX", "Корзина"]) == "Корзина")
        #expect(MailboxDirectory.providerSavesSent(host: "smtp.gmail.com"))
        #expect(!MailboxDirectory.providerSavesSent(host: "smtp.mail.ru"))
    }
}

private struct FixtureSource: MailHeaderSource {
    let accountID: UUID
    let accountName: String
    let rows: [MailHeader]

    func headers(mailbox: String, limit: Int, olderThan sequence: Int?) async throws -> [MailHeader] {
        rows
            .filter { $0.mailbox == mailbox }
            .filter { sequence == nil || $0.sequence < sequence! }
            .sorted { $0.sequence > $1.sequence }
            .prefix(limit)
            .map { $0 }
    }
}

private func header(_ account: UUID, _ name: String, _ subject: String, sequence: Int, date: TimeInterval) -> MailHeader {
    MailHeader(id: "\(name)-\(subject)", accountID: account, accountName: name, mailbox: "INBOX", sequence: sequence, date: Date(timeIntervalSince1970: date), subject: subject)
}
