// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SMTP
import Testing

extension Server: CaseIterable {

    // MARK: AOL
    static var aol: Self {
        Server(
            .ssl,
            hostname: "smtp.aol.com",
            username: "",
            password: "",
            port: 465
        )
    }

    // MARK: Gmail
    static var gmail: Self {
        Server(
            .ssl,
            hostname: "smtp.gmail.com",
            username: "",
            password: "",
            port: 465
        )
    }

    // MARK: iCloud
    static var icloud: Self {
        Server(
            .startTLS,
            hostname: "smtp.mail.me.com",
            username: "",
            password: "",
            port: 587
        )
    }

    // MARK: Outlook
    static var outlook: Self {
        Server(
            .startTLS,
            hostname: "smtp-mail.outlook.com",
            username: "",
            password: "",
            port: 587
        )
    }

    var isDisabled: Bool { username.isEmpty || password.isEmpty }

    static func allCases(disabled: Bool) -> [Self] {
        allCases.filter { $0.isDisabled == disabled }
    }

    // MARK: CaseIterable
    public static let allCases: [Self] = [.aol, .gmail, .icloud, .outlook]
}

// Catch when test account usernames or passwords are leaking
@Test(arguments: Server.allCases) func isDisabled(_ server: Server) {
    #expect(server.username.isEmpty == true)
    #expect(server.password.isEmpty == true)
}
