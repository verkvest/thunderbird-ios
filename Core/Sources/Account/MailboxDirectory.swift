// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Picks a mailbox path out of an IMAP LIST result. Names are matched on the last
/// path component so `[Gmail]/Sent Mail` and `Отправленные` both resolve.
public enum MailboxDirectory {
    public static func sent(in names: [String]) -> String? {
        match(names, tokens: ["sent", "sent mail", "sent items", "sent messages", "отправленные", "enviados", "enviado"])
    }

    public static func archive(in names: [String]) -> String? {
        match(names, tokens: ["archive", "archives", "archived", "archivo", "archivados", "архив", "all mail"])
    }

    public static func trash(in names: [String]) -> String? {
        match(names, tokens: ["trash", "deleted", "deleted items", "deleted messages", "bin", "papelera", "корзина", "удаленные", "удалённые"])
    }

    /// Gmail stores a Sent copy when the message is submitted to `smtp.gmail.com`.
    public static func providerSavesSent(host: String) -> Bool {
        let host: String = host.lowercased()
        return host == "smtp.gmail.com" || host == "gmail.com" || host == "googlemail.com" || host.hasSuffix(".gmail.com") || host.hasSuffix(".googlemail.com")
    }

    private static func match(_ names: [String], tokens: [String]) -> String? {
        let ranked: [(String, String)] = names.map { name in
            let leaf: String = name.split(whereSeparator: { $0 == "/" || $0 == "." }).last.map(String.init)?.lowercased() ?? name.lowercased()
            return (name, leaf)
        }
        for token in tokens {
            if let exact: (String, String) = ranked.first(where: { $0.1 == token }) {
                return exact.0
            }
        }
        for token in tokens {
            if let prefix: (String, String) = ranked.first(where: { $0.1.hasPrefix(token) }) {
                return prefix.0
            }
        }
        return nil
    }
}
