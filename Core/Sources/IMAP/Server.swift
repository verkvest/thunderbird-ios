// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// ``IMAPClient`` connects to `Server`.
public struct Server: CustomStringConvertible, Equatable, Sendable {
    public enum Authentication: String, Equatable, Sendable {
        case password
        case xoauth2
    }

    public let connectionSecurity: ConnectionSecurity
    public let hostname: String
    public let username: String?
    public let password: String?
    public let authentication: Authentication
    public let port: Int

    /// `Server` can be configured with or without basic auth credentials.
    ///
    /// User name and password can be provided at `login`, or another mechanism can be used to `authenticate`.
    public init(
        _ connectionSecurity: ConnectionSecurity = .tls,
        hostname: String,
        username: String? = nil,
        password: String? = nil,
        authentication: Authentication = .password,
        port: Int = 993
    ) {
        self.connectionSecurity = connectionSecurity
        self.hostname = hostname
        self.username = username
        self.password = password
        self.authentication = authentication
        self.port = port
    }

    // MARK: CustomStringConvertible
    public var description: String { "\(hostname):\(port)" }
}
