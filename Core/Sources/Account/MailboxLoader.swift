// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// One header row used to page and merge mailboxes without a live server.
public struct MailHeader: Equatable, Identifiable, Sendable {
    public var id: String
    public var accountID: UUID
    public var accountName: String
    public var mailbox: String
    public var sequence: Int
    public var date: Date
    public var subject: String

    public init(id: String, accountID: UUID, accountName: String, mailbox: String, sequence: Int, date: Date, subject: String) {
        self.id = id
        self.accountID = accountID
        self.accountName = accountName
        self.mailbox = mailbox
        self.sequence = sequence
        self.date = date
        self.subject = subject
    }
}

public protocol MailHeaderSource: Sendable {
    var accountID: UUID { get }
    var accountName: String { get }
    func headers(mailbox: String, limit: Int, olderThan sequence: Int?) async throws -> [MailHeader]
}

public enum MailboxPages {
    public static let size: Int = 40

    /// Newest first. A unified inbox keeps only `limit` rows after the per-account pages are combined.
    public static func merge(_ pages: [[MailHeader]], limit: Int) -> [MailHeader] {
        let sorted: [MailHeader] = pages.flatMap { $0 }.sorted { lhs, rhs in
            if lhs.date != rhs.date { return lhs.date > rhs.date }
            if lhs.sequence != rhs.sequence { return lhs.sequence > rhs.sequence }
            return lhs.id > rhs.id
        }
        return Array(sorted.prefix(max(limit, 0)))
    }
}

public struct MailboxLoader: Sendable {
    public var pageSize: Int
    public var sources: [any MailHeaderSource]

    public init(sources: [any MailHeaderSource], pageSize: Int = MailboxPages.size) {
        self.sources = sources
        self.pageSize = pageSize
    }

    /// `accountID == nil` loads a unified mailbox. `olderThan` is the oldest sequence already shown, per account.
    public func load(accountID: UUID?, mailbox: String, olderThan: [UUID: Int] = [:]) async throws -> [MailHeader] {
        let chosen: [any MailHeaderSource] = sources.filter { accountID == nil || $0.accountID == accountID }
        var pages: [[MailHeader]] = []
        for source in chosen {
            let page: [MailHeader] = try await source.headers(mailbox: mailbox, limit: pageSize, olderThan: olderThan[source.accountID])
            pages.append(page)
        }
        return MailboxPages.merge(pages, limit: pageSize)
    }
}
