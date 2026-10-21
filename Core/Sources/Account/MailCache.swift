// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Local mailbox cache. Headers and bodies only — never passwords or OAuth tokens.
public enum MailCache {
    public struct Header: Codable, Equatable, Identifiable, Hashable, Sendable {
        public var id: String
        public var accountID: UUID
        public var accountName: String
        public var mailbox: String
        public var uid: UInt32?
        public var sequence: Int
        public var subject: String
        public var from: String
        public var date: Date?
        public var unread: Bool
        public var flagged: Bool
        public var preview: String

        public init(
            id: String,
            accountID: UUID,
            accountName: String,
            mailbox: String,
            uid: UInt32?,
            sequence: Int,
            subject: String,
            from: String,
            date: Date?,
            unread: Bool,
            flagged: Bool,
            preview: String
        ) {
            self.id = id
            self.accountID = accountID
            self.accountName = accountName
            self.mailbox = mailbox
            self.uid = uid
            self.sequence = sequence
            self.subject = subject
            self.from = from
            self.date = date
            self.unread = unread
            self.flagged = flagged
            self.preview = preview
        }
    }

    public struct Attachment: Codable, Equatable, Sendable {
        public var filename: String
        public var mime: String
        public var data: Data

        public init(filename: String, mime: String, data: Data) {
            self.filename = filename
            self.mime = mime
            self.data = data
        }
    }

    public struct Body: Codable, Equatable, Sendable {
        public var id: String
        public var html: String?
        public var text: String?
        public var attachments: [Attachment]

        public init(id: String, html: String?, text: String?, attachments: [Attachment]) {
            self.id = id
            self.html = html
            self.text = text
            self.attachments = attachments
        }
    }
}

public struct MailCacheStore: Sendable {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    public static func applicationSupport() throws -> Self {
        let base: URL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let root: URL = base.appending(path: "MailCache", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return Self(root: root)
    }

    public func headers(accountID: UUID, mailbox: String) -> [MailCache.Header] {
        guard let data: Data = try? Data(contentsOf: headerURL(accountID: accountID, mailbox: mailbox)) else { return [] }
        return (try? JSONDecoder.mailCache.decode([MailCache.Header].self, from: data)) ?? []
    }

    public func save(headers: [MailCache.Header], accountID: UUID, mailbox: String) throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let data: Data = try JSONEncoder.mailCache.encode(headers)
        try data.write(to: headerURL(accountID: accountID, mailbox: mailbox), options: .atomic)
    }

    public func body(id: String) -> MailCache.Body? {
        guard let data: Data = try? Data(contentsOf: bodyURL(id: id)) else { return nil }
        return try? JSONDecoder.mailCache.decode(MailCache.Body.self, from: data)
    }

    public func save(body: MailCache.Body) throws {
        let directory: URL = root.appending(path: "bodies", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data: Data = try JSONEncoder.mailCache.encode(body)
        try data.write(to: bodyURL(id: body.id), options: .atomic)
    }

    private func headerURL(accountID: UUID, mailbox: String) -> URL {
        let safe: String = mailbox.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: " ", with: "_")
        return root.appending(path: "\(accountID.uuidString)-\(safe).json")
    }

    private func bodyURL(id: String) -> URL {
        let safe: String = id.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? id
        return root.appending(path: "bodies", directoryHint: .isDirectory).appending(path: "\(safe).json")
    }
}

extension JSONEncoder {
    static var mailCache: JSONEncoder {
        let encoder: JSONEncoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var mailCache: JSONDecoder {
        let decoder: JSONDecoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
