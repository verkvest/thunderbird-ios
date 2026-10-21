// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import JMAP
import Testing

struct JMAPErrorTests {

    // MARK: CustomStringConvertible
    @Test func description() {
        #expect(JMAPError.method(.accountNotFound).description == "Method error: Account not found")
        #expect(JMAPError.request(RequestError(.notRequest, detail: "unrecognized value")).description == "Request error: Not request; unrecognized value")
        #expect(JMAPError.request(RequestError(.unknownCapability)).description == "Request error: Unknown capability")
        #expect(JMAPError.set(.requestTooLarge).description == "Set error: Request too large")
        #expect(JMAPError.underlying(URLError(.cannotConnectToHost)).description == "Underlying error: The operation couldn’t be completed. (NSURLErrorDomain error -1004.)")
    }
}
