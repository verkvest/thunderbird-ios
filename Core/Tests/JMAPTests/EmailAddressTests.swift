// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
@testable import JMAP
import Testing

struct EmailAddressTests {

    // MARK: Codable
    @Test func encode() throws {
        /*
        #expect(try JSONEncoder().encode(EmailAddress("name@example.com", label: "Example Name")) == "\"Example Name <name@example.com>\"".data(using: .utf8))
        #expect(try JSONEncoder().encode(EmailAddress("name@example.com")) == "\"name@example.com\"".data(using: .utf8)) */
    }

    @Test func decoderInit() throws {
        let emailAddresses: [EmailAddressProtocol] = try JSONDecoder().decode([EmailAddress.Group].self, from: data).erased()
        #expect(emailAddresses.count == 5)
        #expect((emailAddresses[0] as? EmailAddress.Group)?.name == "Named Group")
        #expect((emailAddresses[0] as? EmailAddress.Group)?.addresses.count == 2)
        #expect((emailAddresses[1] as? EmailAddress)?.email == "emptyname@example.com")
        #expect((emailAddresses[1] as? EmailAddress)?.name == nil)
        #expect((emailAddresses[2] as? EmailAddress)?.email == "nullname@example.com")
        #expect((emailAddresses[2] as? EmailAddress)?.name == nil)
        #expect((emailAddresses[3] as? EmailAddress)?.email == "noname@example.com")
        #expect((emailAddresses[3] as? EmailAddress)?.name == nil)
        #expect((emailAddresses[4] as? EmailAddress)?.email == "name@example.com")
        #expect((emailAddresses[4] as? EmailAddress)?.name == "Named Example")

        // Test backward compatibility with previous encoding as string
        let string: Data = "\"Named Example <name@example.com>\"".data(using: .utf8)!
        let emailAddress: EmailAddress = try JSONDecoder().decode(EmailAddress.self, from: string)
        #expect(emailAddress.email == "name@example.com")
        #expect(emailAddress.name == "Named Example")
    }
}

// swift-format-ignore
private let data: Data = """
[
    {
        "addresses": [
            {
                "email": "name@example.com",
                "name": "Named Example"
            },
            {
                "email": "noname@example.com"
            }
        ],
        "name": "Named Group"
    },
    {
        "email": "emptyname@example.com",
        "name": ""
    },
    {
        "email": "nullname@example.com",
        "name": null
    },
    {
        "addresses": [
            {
                "email": "noname@example.com"
            }
        ]
    },
    {
        "email": "name@example.com",
        "name": "Named Example"
    }
]
""".data(using: .utf8)!
