// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import JMAP
import Testing

extension Server: CaseIterable {

    // MARK: Fastmail
    static var fastmail: Self {
        Server(
            authorization: nil,
            host: "")
    }

    var isDisabled: Bool { (authorization ?? .empty).isEmpty }

    static func allCases(disabled: Bool) -> [Self] {
        allCases.filter { $0.isDisabled == disabled }
    }

    // MARK: CaseIterable
    public static let allCases: [Self] = [.fastmail]
}

// Catch when test account usernames or passwords are leaking
@Test(arguments: Server.allCases) func isDisabled(_ server: Server) {
    #expect((server.authorization?.isEmpty ?? true) == true)
    #expect(server.authorization == nil)
}
