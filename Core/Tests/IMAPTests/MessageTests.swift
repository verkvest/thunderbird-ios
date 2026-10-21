// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import Testing

struct MessageTests {

}

struct MessageSetTests {
    @Test func messages() {
        let messageSet: MessageSet = [
            4: Message([.uid(9)]),
            1: Message([.uid(1)]),
            5: Message([.uid(2)]),
            3: Message([.uid(5)]),
            2: Message([.uid(3)])
        ]
        #expect(messageSet.messages.compactMap { $0.uid } == [1, 3, 5, 9, 2])
    }
}
