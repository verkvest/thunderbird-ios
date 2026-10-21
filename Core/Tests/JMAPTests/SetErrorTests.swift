// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import JMAP
import Testing

struct SetErrorTests {
    @Test func valueInit() throws {
        #expect(SetError(data) == .invalidProperties)
    }
}

// swift-format-ignore
private let data: Data = """
{
    "properties": [
        "name"
    ],
    "type": "invalidProperties"
}
""".data(using: .utf8)!
