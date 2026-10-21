// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import Testing

struct VoidCommandTests {
    @Test func name() {
        #expect(VoidCommand(.capability).name == "capability")
        #expect(VoidCommand(.close).name == "close")
        #expect(VoidCommand(.expunge).name == "expunge")
        #expect(VoidCommand(.logout).name == "logout")
        #expect(VoidCommand(.unselect).name == "unselect")
    }
}
