// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

struct EmailAddressTests {
    @Test func host() throws {
        #expect(try "user@example.com".host == "example.com")
        #expect(try "h@x0r@192.168.1.1".host == "192.168.1.1")
        #expect(try "example.com".host == "example.com")
        #expect(throws: URLError.self) {
            try "abc@".host
        }
        #expect(throws: URLError.self) {
            try " ".host
        }
    }

    @Test func local() throws {
        #expect(try "user@example.com".local == "user")
        #expect(try "h@x0r@192.168.1.1".local == "h@x0r")
        #expect(throws: URLError.self) {
            try "example.com".local
        }
    }

    @Test func query() throws {
        #expect(try "user@example.com".query(.autodiscover) == "_autodiscover._tcp.example.com")
        #expect(try "h@x0r@192.168.1.1".query(.imap) == "_imap._tcp.192.168.1.1")
        #expect(try "example.com".query(.smtp) == "_smtp._tcp.example.com")
        #expect(throws: URLError.self) {
            try "abc@".query(.jmap)
        }
    }
}
