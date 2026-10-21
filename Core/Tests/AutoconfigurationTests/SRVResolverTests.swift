// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Testing

struct SRVResolverTests {
    @Test func query() async throws {

        // Thundermail
        #expect(try await SRVResolver().query("_jmap._tcp.thundermail.com").first?.description == "SRVRecord(host=mail.thundermail.com, port=443, weight=1, priority=0)")
        #expect(try await SRVResolver().query("_imaps._tcp.thundermail.com").first?.description == "SRVRecord(host=mail.thundermail.com, port=993, weight=1, priority=0)")
        #expect(try await SRVResolver().query("_imap._tcp.thundermail.com").first?.description == "SRVRecord(host=mail.thundermail.com, port=143, weight=1, priority=0)")
        #expect(try await SRVResolver().query("_submissions._tcp.thundermail.com").first?.description == "SRVRecord(host=mail.thundermail.com, port=465, weight=1, priority=0)")
        #expect(try await SRVResolver().query("_submission._tcp.thundermail.com").first?.description == "SRVRecord(host=mail.thundermail.com, port=587, weight=1, priority=0)")
        #expect(try await SRVResolver().query("_autodiscover._tcp.thundermail.com") == [])
        #expect(try await SRVResolver().query("_pop3._tcp.thundermail.com") == [])

        // Fastmail
        #expect(try await SRVResolver().query("_jmap._tcp.fastmail.com").first?.description == "SRVRecord(host=api.fastmail.com, port=443, weight=1, priority=0)")
        #expect(try await SRVResolver().query("_autodiscover._tcp.fastmail.com").first?.description == "SRVRecord(host=autodiscover.fastmail.com, port=443, weight=1, priority=0)")
        #expect(try await SRVResolver().query("_imaps._tcp.fastmail.com").first?.description == "SRVRecord(host=imap.fastmail.com, port=993, weight=1, priority=0)")
        #expect(try await SRVResolver().query("_submissions._tcp.fastmail.com").first?.description == "SRVRecord(host=smtp.fastmail.com, port=465, weight=1, priority=0)")
        #expect(try await SRVResolver().query("_pop3._tcp.fastmail.com") == [])
        #expect(try await SRVResolver().query("_submission._tcp.fastmail.com") == [])

        // Gmail
        #expect(try await SRVResolver().query("_imaps._tcp.gmail.com").first?.description == "SRVRecord(host=imap.gmail.com, port=993, weight=0, priority=5)")
        #expect(try await SRVResolver().query("_submission._tcp.gmail.com").first?.description == "SRVRecord(host=smtp.gmail.com, port=587, weight=0, priority=5)")
        #expect(try await SRVResolver().query("_autodiscover._tcp.gmail.com") == [])
        #expect(try await SRVResolver().query("_jmap._tcp.gmail.com") == [])
        #expect(try await SRVResolver().query("_pop3._tcp.gmail.com") == [])
    }
}
