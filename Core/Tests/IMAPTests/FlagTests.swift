// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import IMAP
import Testing

struct FlagTests {

    // MARK: CustomStringConvertible
    @Test func description() {
        #expect(Flag.answered.description == "\\Answered")
        #expect(Flag.deleted.description == "\\Deleted")
        #expect(Flag.draft.description == "\\Draft")
        #expect(Flag.flagged.description == "\\Flagged")
        #expect(Flag.seen.description == "\\Seen")
    }
}
