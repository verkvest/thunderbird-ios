// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import JMAP
import Testing

struct AuthorizationTests {
    @Test func token() {
        #expect(Authorization.basic("user@example.com", "fAK3-PASs-w0rD").token == "dXNlckBleGFtcGxlLmNvbTpmQUszLVBBU3MtdzByRA==")
        #expect(Authorization.basic("", "").token == "Og==")
        #expect(Authorization.bearer("dXNlckBleGFtcGxlLmNvbTpmQUszLVBBU3MtdzByRA").token == "dXNlckBleGFtcGxlLmNvbTpmQUszLVBBU3MtdzByRA")
        #expect(Authorization.bearer("").token == "")
    }

    @Test func isEmpty() {
        #expect(Authorization.basic("user@example.com", "fAK3-PASs-w0rD").isEmpty == false)
        #expect(Authorization.basic("", "f").isEmpty == false)
        #expect(Authorization.basic("u", "").isEmpty == false)
        #expect(Authorization.basic("", "").isEmpty == true)
        #expect(Authorization.bearer("dXNlckBleGFtcGxlLmNvbTpmQUszLVBBU3MtdzByRA").isEmpty == false)
        #expect(Authorization.bearer("d").isEmpty == false)
        #expect(Authorization.bearer("").isEmpty == true)
    }

    // MARK: CustomStringConvertible
    @Test func description() {
        #expect(Authorization.basic("user@example.com", "fAK3-PASs-w0rD").description == "Basic dXNlckBleGFtcGxlLmNvbTpmQUszLVBBU3MtdzByRA==")
        #expect(Authorization.basic("", "").description == "Basic Og==")
        #expect(Authorization.bearer("dXNlckBleGFtcGxlLmNvbTpmQUszLVBBU3MtdzByRA").description == "Bearer dXNlckBleGFtcGxlLmNvbTpmQUszLVBBU3MtdzByRA")
        #expect(Authorization.bearer("").description == "Bearer ")
    }
}

struct StringTests {
    @Test func base64Encoded() {
        #expect("user@example.com:fAK3-PASs-w0rD".base64Encoded() == "dXNlckBleGFtcGxlLmNvbTpmQUszLVBBU3MtdzByRA==")
        let data: Data = Data(base64Encoded: "dXNlckBleGFtcGxlLmNvbTpmQUszLVBBU3MtdzByRA==")!
        #expect(String(data: data, encoding: .utf8) == "user@example.com:fAK3-PASs-w0rD")
        #expect(":".base64Encoded() == "Og==")
        #expect("".base64Encoded() == "")
    }
}
