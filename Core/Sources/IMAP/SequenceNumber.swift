// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import NIOIMAPCore

public typealias SequenceNumber = NIOIMAPCore.SequenceNumber
public typealias SequenceSet = NIOIMAPCore.MessageIdentifierSetNonEmpty<SequenceNumber>

extension SequenceNumber: @retroactive CustomStringConvertible {

    // MARK: CustomStringConvertible
    public var description: String { debugDescription }
}

extension SequenceSet {
    init(_ sequenceNumber: SequenceNumber) {
        self.init(range: MessageIdentifierRange(sequenceNumber))
    }

    /// The newest `limit` messages. Sequence 1 is the oldest message in the mailbox.
    public static func newest(limit: Int, messageCount: Int) -> Self? {
        guard messageCount > 0, limit > 0 else { return nil }
        let upper: UInt32 = UInt32(min(messageCount, Int(UInt32.max - 1)))
        let lower: UInt32 = UInt32(max(1, messageCount - limit + 1))
        return Self(range: MessageIdentifierRange(SequenceNumber(rawValue: lower)...SequenceNumber(rawValue: upper)))
    }
}
