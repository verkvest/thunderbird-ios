// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import JMAP
import Testing

struct URLSessionTests {
    @Test(arguments: Server.allCases(disabled: false)) func jmapAPI(server: Server) async throws {
        let session: Session = try await URLSession.shared.jmapSession(server: server)
        guard let accountID: String = session.accounts.keys.first else {
            throw MethodError.accountNotFound
        }
        guard let authorization: Authorization = server.authorization else {
            throw URLError(.userAuthenticationRequired)
        }
        let responses: [any MethodResponse] = try await URLSession.shared.jmapAPI(
            [
                Mailbox.GetMethod(accountID)  // Test with account-agnostic method
            ],
            url: session.apiURL,
            authorization: authorization
        )
        try #require(responses.count == 1)
        guard let response: MethodGetResponse = responses.first as? MethodGetResponse else {
            throw MethodError.invalidArguments
        }
        let mailboxes: [Mailbox] = try response.decode([Mailbox].self)
        #expect(mailboxes.count > 0)
        #expect(mailboxes.compactMap { $0.role }.contains(.inbox) == true)
    }

    @Test(arguments: Server.allCases(disabled: false)) func jmapSession(server: Server) async throws {
        let session: Session = try await URLSession.shared.jmapSession(server: server)
        print(session)
    }
}
