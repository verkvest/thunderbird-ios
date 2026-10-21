// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import JMAP
import Testing

struct URLTests {
    @Test func jmapSession() throws {
        #expect(try URL.jmapSession(host: "api.example.com").absoluteString == "https://api.example.com/jmap/session")
        #expect(throws: URLError.self) {
            try URL.jmapSession(host: "")
        }
    }

    @Test func jmap() throws {
        #expect(try URL.jmap(host: "api.example.com").absoluteString == "https://api.example.com")
        #expect(try URL.jmap(host: "api.example.com", path: "/jmap/session").absoluteString == "https://api.example.com/jmap/session")
        #expect(try URL.jmap(host: "api.example.com", path: "jmap/session").absoluteString == "https://api.example.com/jmap/session")
        #expect(throws: URLError.self) {
            try URL.jmap(host: "")
        }
    }
}
