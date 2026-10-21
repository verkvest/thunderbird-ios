// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import IMAP
import Testing

struct IMAPErrorTests {

    // MARK: CustomStringConvertible
    @Test func description() {
        #expect(IMAPError.capabilityNotSupported(.idle).description == "IDLE not supported")
        #expect(IMAPError.commandFailed("CAPABILITY failed.").description == "CAPABILITY failed.")
        #expect(IMAPError.commandFailed(CapabilityCommand()).description == "Capability command failed")
        #expect(IMAPError.commandNotSupported("capability command").description == "Capability command not supported")
        #expect(IMAPError.commandNotSupported(CapabilityCommand()).description == "Capability command not supported")
        #expect(IMAPError.timedOut(seconds: 5).description == "Timed out after 5 seconds")
        #expect(IMAPError.timedOut(seconds: 0).description == "Timed out after 0 seconds")
        #expect(IMAPError.timedOut(seconds: 1).description == "Timed out after 1 second")
        #expect(IMAPError.underlying(URLError(.badURL)).description == "Underlying error: The operation couldn’t be completed. (NSURLErrorDomain error -1000.)")
    }
}
