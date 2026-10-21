// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

struct URLTests {
    @Test func autoconfig() throws {
        #expect(try URL.autoconfig("user@example.com", source: .provider).absoluteString == "https://autoconfig.example.com/mail/config-v1.1.xml?emailaddress=user@example.com")
        #expect(try URL.autoconfig("user@example.com", source: .wellKnown).absoluteString == "https://example.com/.well-known/autoconfig/mail/config-v1.1.xml")
        #expect(try URL.autoconfig("user@example.com").absoluteString == "https://autoconfig.thunderbird.net/v1.1/example.com")
    }

    @Test func provider() throws {
        #expect(try URL.provider("user@example.com").absoluteString == "https://autoconfig.example.com/mail/config-v1.1.xml?emailaddress=user@example.com")
        #expect(try URL.provider("h@x0r@192.168.1.1").absoluteString == "https://autoconfig.192.168.1.1/mail/config-v1.1.xml?emailaddress=h@x0r@192.168.1.1")
        #expect(try URL.provider("example.com").absoluteString == "https://autoconfig.example.com/mail/config-v1.1.xml")
        #expect(throws: URLError.self) {
            try URL.provider("@")
        }
    }

    @Test func wellKnown() throws {
        #expect(try URL.wellKnown("user@example.com").absoluteString == "https://example.com/.well-known/autoconfig/mail/config-v1.1.xml")
        #expect(try URL.wellKnown("h@x0r@192.168.1.1").absoluteString == "https://192.168.1.1/.well-known/autoconfig/mail/config-v1.1.xml")
        #expect(try URL.wellKnown("example.com").absoluteString == "https://example.com/.well-known/autoconfig/mail/config-v1.1.xml")
        #expect(throws: URLError.self) {
            try URL.wellKnown("")
        }
    }

    @Test func ispDB() throws {
        #expect(try URL.ispDB("user@example.com").absoluteString == "https://autoconfig.thunderbird.net/v1.1/example.com")
        #expect(try URL.ispDB("h@x0r@192.168.1.1").absoluteString == "https://autoconfig.thunderbird.net/v1.1/192.168.1.1")
        #expect(try URL.ispDB("example.com").absoluteString == "https://autoconfig.thunderbird.net/v1.1/example.com")
        #expect(throws: URLError.self) {
            try URL.ispDB(" ")
        }
    }
}
