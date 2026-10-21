// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import JMAP
import Testing

struct ThreadTests {
    @Test func decoderInit() throws {
        let threads: [JMAP.Thread] = try JSONDecoder().decode([JMAP.Thread].self, from: data)
        try #require(threads.count == 2)
    }
}

// swift-format-ignore
private let data: Data = """
[
    {
        "id": "T1bebe52081852054",
        "emailIds": [
            "M8a183cc18aec2b46bd7b7f11",
            "Md80606e8b5e8b03eba586b5f"
        ]
    },
    {
        "emailIds": [
            "Me394340456855ec7556d3649"
        ],
        "id": "T7267ede55dec55d5"
    }
]
""".data(using: .utf8)!
