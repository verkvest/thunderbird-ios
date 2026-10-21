// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

struct SRVRecordTests {
    @Test func dataInit() throws {
        #expect(try SRVRecord(Data(base64Encoded: "AAAAAQG7BG1haWwLdGh1bmRlcm1haWwDY29tAA==")!).description == "SRVRecord(host=mail.thundermail.com, port=443, weight=1, priority=0)")
        #expect(try SRVRecord(Data(base64Encoded: "AAUAAAPhBGltYXAFZ21haWwDY29tAA==")!).description == "SRVRecord(host=imap.gmail.com, port=993, weight=0, priority=5)")
        #expect(throws: URLError.self) {
            try SRVRecord(Data(base64Encoded: "AAAAAAAAAA==")!)
        }
    }
}
