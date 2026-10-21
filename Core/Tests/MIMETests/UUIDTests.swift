// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import MIME
import Testing

struct UUIDTests {
    @Test func dataBoundary() {
        let uuid: UUID = UUID(uuidString: "A51D5B17-CA61-4FF1-A4A8-C717289B8F9E")!
        #expect(uuid.dataBoundary(3, separator: "", prefix: "mime_", suffix: "_part").description == "mime_A51D5B17CA614FF1_part")
    }

    @Test func uuidString() {
        let uuid: UUID = UUID(uuidString: "A51D5B17-CA61-4FF1-A4A8-C717289B8F9E")!
        #expect(uuid.uuidString(3, separator: "") == "A51D5B17CA614FF1")
        #expect(uuid.uuidString(3, separator: "👎") == "A51D5B17-CA61-4FF1")
        #expect(uuid.uuidString(2, separator: "_") == "A51D5B17_CA61")
        #expect(uuid.uuidString(4) == "A51D5B17-CA61-4FF1-A4A8")
    }
}
