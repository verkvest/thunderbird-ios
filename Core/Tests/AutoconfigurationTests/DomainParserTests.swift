// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Foundation
import Testing

struct DomainParserTests {
    @Test func hostInit() throws {
        let suffixList: [String] = try SuffixListParser(data: suffixList).suffixList
        #expect(try DomainParser(host: "alt1.smtp.google.com", suffixList: suffixList).domain == "google.com")
        #expect(try DomainParser(host: "alt1.smtp.google.com", suffixList: suffixList).host == "alt1.smtp.google.com")
        #expect(try DomainParser(host: "alt1.smtp.google.com", suffixList: suffixList).suffix == "com")
        #expect(try DomainParser(host: "imap.mail-provider.com.au", suffixList: suffixList).domain == "mail-provider.com.au")
        #expect(try DomainParser(host: "imap.mail-provider.com.au", suffixList: suffixList).host == "imap.mail-provider.com.au")
        #expect(try DomainParser(host: "imap.mail-provider.com.au", suffixList: suffixList).suffix == "com.au")
        #expect(try DomainParser(host: "mail.mx1.example.net.uk", suffixList: suffixList).domain == "example.net.uk")
        #expect(try DomainParser(host: "mail.mx1.example.net.uk", suffixList: suffixList).host == "mail.mx1.example.net.uk")
        #expect(try DomainParser(host: "mail.mx1.example.net.uk", suffixList: suffixList).suffix == "net.uk")
        #expect(throws: URLError.self) {
            try DomainParser(host: "host.example", suffixList: suffixList)
        }
    }
}
