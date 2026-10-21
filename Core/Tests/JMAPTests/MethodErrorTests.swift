// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import JMAP
import Testing

struct MethodErrorTests {

    // MARK: Decodable
    @Test func decoderInit() throws {
        let errors: [MethodError] = try JSONDecoder().decode([MethodError].self, from: data)
        try #require(errors.count == 2)
        #expect(errors[0] == .accountNotSupportedByMethod)
        #expect(errors[1] == .unknownMethod)
    }
}

// swift-format-ignore
private let data: Data = """
[
    [
        "error",
        {
            "type": "accountNotSupportedByMethod"
        },
        ""
    ],
    [
        "error",
        {
            "type": "unknownMethod"
        },
        "call-id"
    ]
]
""".data(using: .utf8)!
