// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import IMAP
import Testing

struct SequencePageTests {
    @Test func newestPageIsTheHighEndOfTheMailbox() {
        let set: SequenceSet? = SequenceSet.newest(limit: 2, messageCount: 10)
        #expect(set?.min().rawValue == 9)
        #expect(set?.max().rawValue == 10)
        #expect(SequenceSet.newest(limit: 40, messageCount: 0) == nil)
        let older: SequenceSet? = SequenceSet.newest(limit: 40, messageCount: 60)
        #expect(older?.min().rawValue == 21)
        #expect(older?.max().rawValue == 60)
    }
}
