// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Foundation
import Observation

/// Inbox state for the iPhone: cache first, then a page of headers, then older pages.
@MainActor
@Observable
final class MailboxModel {
    var rows: [MailCache.Header] = []
    var selectedAccountID: UUID?
    var mailbox: String = "INBOX"
    var isLoading: Bool = false
    var errorMessage: String?
    var hasMore: Bool = true
    var actionTick: Int = 0
    var folderManagers: [UUID: FolderManager] = [:]
    private var exhausted: Set<UUID> = []
    private var didShowCache: Bool = false
    private var idleTask: Task<Void, Never>?
    private let store: MailCacheStore

    init() {
        store = (try? MailCacheStore.applicationSupport()) ?? MailCacheStore(root: FileManager.default.temporaryDirectory)
    }

    func title(accounts: [Account]) -> String {
        if mailbox != "INBOX" { return mailbox }
        if let selectedAccountID, let account: Account = accounts.first(where: { $0.id == selectedAccountID }) {
            return account.name
        }
        return accounts.count > 1 ? "unified_inbox" : "inbox_header"
    }

    func bootstrap(accounts: [Account]) async {
        showCache(accounts: accounts)
        await refresh(accounts: accounts)
    }

    func showCache(accounts: [Account]) {
        guard !didShowCache else { return }
        didShowCache = true
        rows = cachedRows(accounts: accounts)
    }

    func select(accountID: UUID?, mailbox: String, accounts: [Account]) async {
        selectedAccountID = accountID
        self.mailbox = mailbox
        exhausted = []
        hasMore = true
        didShowCache = false
        rows = []
        showCache(accounts: accounts)
        await refresh(accounts: accounts)
        await restartIdle(accounts: accounts, active: true)
    }

    func refresh(accounts: [Account]) async {
        isLoading = true
        errorMessage = nil
        exhausted = []
        defer { isLoading = false }
        do {
            let page: [MailCache.Header] = try await fetch(accounts: accounts, olderThan: [:])
            rows = page
            hasMore = !page.isEmpty
            try save(page, accounts: accounts)
        } catch {
            errorMessage = error.localizedDescription
            if rows.isEmpty {
                rows = cachedRows(accounts: accounts)
            }
        }
    }

    func loadMore(accounts: [Account]) async {
        guard hasMore, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        var cursors: [UUID: Int] = [:]
        for row in rows {
            let current: Int = cursors[row.accountID] ?? Int.max
            cursors[row.accountID] = min(current, row.sequence)
        }
        do {
            let page: [MailCache.Header] = try await fetch(accounts: accounts, olderThan: cursors)
            let known: Set<String> = Set(rows.map(\.id))
            let fresh: [MailCache.Header] = page.filter { !known.contains($0.id) }
            rows.append(contentsOf: fresh)
            if fresh.isEmpty { hasMore = false }
            try save(rows, accounts: accounts)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadFolders(account: Account) async {
        let manager: FolderManager = folderManagers[account.id] ?? FolderManager(account: account)
        let boxes: [Mailbox] = (try? await account.mailboxes()) ?? []
        await manager.refreshFolders(mailboxes: boxes)
        folderManagers[account.id] = manager
    }

    func archive(_ header: MailCache.Header, accounts: [Account]) async {
        await move(header, accounts: accounts, destination: MailboxDirectory.archive(in:))
    }

    func delete(_ header: MailCache.Header, accounts: [Account]) async {
        await move(header, accounts: accounts, destination: MailboxDirectory.trash(in:))
    }

    func toggleRead(_ header: MailCache.Header, accounts: [Account]) async {
        guard let uid: UID = uid(header), let account: Account = accounts.first(where: { $0.id == header.accountID }) else { return }
        actionTick += 1
        let seen: Bool = header.unread
        update(header.id) { row in
            row.unread = !seen
        }
        try? await account.setSeen(seen, uid: uid)
    }

    func toggleFlag(_ header: MailCache.Header, accounts: [Account]) async {
        guard let uid: UID = uid(header), let account: Account = accounts.first(where: { $0.id == header.accountID }) else { return }
        actionTick += 1
        let flagged: Bool = !header.flagged
        update(header.id) { row in
            row.flagged = flagged
        }
        try? await account.setFlagged(flagged, uid: uid)
    }

    func open(_ header: MailCache.Header, accounts: [Account]) async -> Email? {
        guard let account: Account = accounts.first(where: { $0.id == header.accountID }) else { return nil }
        let stub: Email = Email(subject: header.subject, uid: uid(header), id: header.id)
        let full: Email = (try? await account.email(stub, in: header.mailbox)) ?? stub
        let body: MailCache.Body = MailCache.Body(
            id: header.id,
            html: full.body?.html(),
            text: full.body?.text,
            attachments: (full.body?.attachments ?? []).enumerated().map { index, attachment in
                MailCache.Attachment(filename: "attachment-\(index + 1)", mime: attachment.contentType.description, data: attachment.data)
            }
        )
        try? store.save(body: body)
        if header.unread {
            update(header.id) { $0.unread = false }
            if let uid: UID = uid(header) {
                try? await account.setSeen(true, uid: uid)
            }
        }
        return full
    }

    func cachedBody(id: String) -> MailCache.Body? {
        store.body(id: id)
    }

    func restartIdle(accounts: [Account], active: Bool) async {
        idleTask?.cancel()
        idleTask = nil
        for account in accounts {
            await account.stopWatching()
        }
        guard active, let selectedAccountID, let account: Account = accounts.first(where: { $0.id == selectedAccountID }) else { return }
        let mailbox: String = mailbox
        idleTask = Task {
            guard let events: AsyncStream<IdleEvent> = try? await account.watch(mailbox: mailbox) else { return }
            for await event in events {
                if Task.isCancelled { break }
                if case .status = event {
                    await refresh(accounts: accounts)
                }
            }
        }
    }

    private func move(_ header: MailCache.Header, accounts: [Account], destination: ([String]) -> String?) async {
        guard let uid: UID = uid(header), let account: Account = accounts.first(where: { $0.id == header.accountID }) else { return }
        actionTick += 1
        let names: [String] = ((try? await account.mailboxes()) ?? []).map(\.name)
        guard let target: String = destination(names) else {
            errorMessage = "mailbox_missing"
            return
        }
        do {
            try await account.move(uid: uid, to: target)
            rows.removeAll { $0.id == header.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetch(accounts: [Account], olderThan: [UUID: Int]) async throws -> [MailCache.Header] {
        let chosen: [Account] = accounts.filter { selectedAccountID == nil || $0.id == selectedAccountID }
        var pages: [[MailCache.Header]] = []
        var failures: [String] = []
        for account in chosen {
            if exhausted.contains(account.id) { continue }
            do {
                let cursor: Int? = olderThan[account.id]
                let emails: [Email] = try await account.emails(in: Mailbox(mailbox), limit: MailboxPages.size, olderThan: cursor)
                if emails.count < MailboxPages.size { exhausted.insert(account.id) }
                let map: (Email) -> MailCache.Header = account.cachedHeader(in: mailbox)
                pages.append(emails.map(map))
            } catch {
                failures.append(account.name)
            }
        }
        if pages.isEmpty, let name: String = failures.first {
            throw NSError(domain: "Thunderbird", code: 1, userInfo: [NSLocalizedDescriptionKey: name])
        }
        if !failures.isEmpty {
            errorMessage = failures.joined(separator: ", ")
        }
        let merged: [MailHeader] = MailboxPages.merge(pages.map { page in
            page.map { header in
                MailHeader(
                    id: header.id,
                    accountID: header.accountID,
                    accountName: header.accountName,
                    mailbox: header.mailbox,
                    sequence: header.sequence,
                    date: header.date ?? .distantPast,
                    subject: header.subject
                )
            }
        }, limit: MailboxPages.size)
        let byID: [String: MailCache.Header] = Dictionary(pages.flatMap { $0 }.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return merged.compactMap { byID[$0.id] }
    }

    private func cachedRows(accounts: [Account]) -> [MailCache.Header] {
        let chosen: [Account] = accounts.filter { selectedAccountID == nil || $0.id == selectedAccountID }
        return chosen.flatMap { store.headers(accountID: $0.id, mailbox: mailbox) }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    private func save(_ headers: [MailCache.Header], accounts: [Account]) throws {
        let grouped: [UUID: [MailCache.Header]] = Dictionary(grouping: headers, by: \.accountID)
        for account in accounts where selectedAccountID == nil || account.id == selectedAccountID {
            try store.save(headers: grouped[account.id] ?? [], accountID: account.id, mailbox: mailbox)
        }
    }

    private func update(_ id: String, _ change: (inout MailCache.Header) -> Void) {
        guard let index: Int = rows.firstIndex(where: { $0.id == id }) else { return }
        change(&rows[index])
    }

    private func uid(_ header: MailCache.Header) -> UID? {
        guard let raw: UInt32 = header.uid else { return nil }
        return UID(rawValue: raw)
    }
}
