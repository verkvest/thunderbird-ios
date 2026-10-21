// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import MIME
import Testing

struct MIMEErrorTests {

    // MARK: CustomStringConvertible
    @Test func description() {
        #expect(MIMEError.boundaryLength(0).description == "Multipart data boundary length 0 outside of bounds 1...70")
        #expect(MIMEError.boundaryLength(71).description == "Multipart data boundary length 71 outside of bounds 1...70")
        #expect(MIMEError.contentTypeNotPossible(.text(.html, .utf8)).description == "Content type not possible: text/html; charset=\"UTF-8\"")
        #expect(MIMEError.dataNotDecoded("<data>".data(using: .ascii)!, encoding: .utf8).description == "Multipart data not decoded: <data>")
        #expect(MIMEError.dataNotDecoded("<data>".data(using: .ascii)!).description == "Multipart data not decoded: <data>")
        #expect(MIMEError.dataNotDecoded("🌐".data(using: .utf8)!, encoding: .ascii).description == "Multipart data not decoded: �")
        #expect(MIMEError.dateNotDecoded("not-a-date").description == "Date not decoded: not-a-date")
    }
}
