// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol EmailAddressProtocol: Sendable {
    var addresses: [EmailAddress] { get }
}

/// Shared email address model suitable for IMAP, JMAP and SMTP
public struct EmailAddress: CustomStringConvertible, EmailAddressProtocol, ExpressibleByStringLiteral, Hashable, Identifiable, Sendable {
    public let value: String
    public let label: String?

    public var host: String? {
        URL(string: "http://\(value.components(separatedBy: "@").last!)")?.host()
    }

    public var local: String? {
        value.contains("@") ? value.components(separatedBy: "@").dropLast().joined(separator: "@") : nil
    }

    public var isEmailAddress: Bool { !(host ?? "").isEmpty && !(local ?? "").isEmpty }

    public init(_ value: String, label: String? = nil) {
        let components: [String] = value.trimmed().components(separatedBy: "<")
        if components.count == 2, components[1].hasSuffix(">") {  // "Example Name <name@example.com>"
            self.value = "\(components[1].dropLast())"
            self.label = label ?? components[0].trimmed()
        } else {
            let label: String = label?.trimmed() ?? ""
            self.value = components[0].trimmed()
            self.label = !label.isEmpty ? label : nil
        }
    }

    // MARK: CustomStringConvertible
    public var description: String { !(label ?? "").isEmpty ? "\(label!) <\(value)>" : value }

    // MARK: EmailAddressProtocol
    public var addresses: [Self] { [self] }

    // MARK: ExpressibleByStringLiteral
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

    // MARK: Identifiable
    public var id: String { value }
}

extension EmailAddress {

    /// Shared email address group/list model suitable for IMAP and JMAP
    public struct Group: EmailAddressProtocol, Equatable, Sendable {
        public let label: String?
        public let email: [EmailAddressProtocol]

        public init(_ email: [EmailAddressProtocol], label: String? = nil) {
            let label: String = label?.trimmed() ?? ""
            self.label = !label.isEmpty ? label : nil
            self.email = email
        }

        // MARK: EmailAddressProtocol
        public var addresses: [EmailAddress] { email.flatMap { $0.addresses } }

        // MARK: Equatable
        public static func == (lhs: Self, rhs: Self) -> Bool {
            // Equality ignores labels, positions and grouping
            lhs.addresses.map({ $0.id }).sorted() == rhs.addresses.map({ $0.id }).sorted()
        }
    }
}
