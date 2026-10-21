// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Autoconfiguration
import Testing

struct DNSResolverTests {
    @Test func querySRV() async throws {
        let records: [SRVRecord] = try await DNSResolver.querySRV("username@thundermail.com")
        #expect(records.count == 4)
        #expect(records.first?.description == "SRVRecord(host=mail.thundermail.com, port=143, weight=1, priority=0)")
        #expect(records.last?.description == "SRVRecord(host=mail.thundermail.com, port=587, weight=1, priority=0)")

        #expect(try await DNSResolver.querySRV("username@thundermail.com", service: .imap).first?.description == "SRVRecord(host=mail.thundermail.com, port=143, weight=1, priority=0)")
        #expect(try await DNSResolver.querySRV("username@thundermail.com", service: .submission).first?.description == "SRVRecord(host=mail.thundermail.com, port=587, weight=1, priority=0)")
        #expect(try await DNSResolver.querySRV("username@thundermail.com", service: .jmap).first?.description == "SRVRecord(host=mail.thundermail.com, port=443, weight=1, priority=0)")
        #expect(try await DNSResolver.querySRV("user@fastmail.com", service: .jmap).first?.description == "SRVRecord(host=api.fastmail.com, port=443, weight=1, priority=0)")
        #expect(try await DNSResolver.querySRV("user.name@gmail.com", service: .imaps).first?.description == "SRVRecord(host=imap.gmail.com, port=993, weight=0, priority=5)")
        #expect(try await DNSResolver.querySRV("user.name@gmail.com", service: .submission).first?.description == "SRVRecord(host=smtp.gmail.com, port=587, weight=0, priority=5)")
    }

    @Test func queryMX() async throws {
        let thunderbird: [MXRecord] = try await DNSResolver.queryMX("uname@thunderbird.net")
        #expect(thunderbird.count > 0)
        let fastmail: [MXRecord] = try await DNSResolver.queryMX("user@fastmail.com")
        #expect(fastmail.count > 0)
        let google: [MXRecord] = try await DNSResolver.queryMX("user.name@gmail.com")
        #expect(google.count > 0)
    }
}
