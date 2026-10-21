// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import IMAP
import MIME
import NIOIMAPCore
import Testing

struct InternetMessageDateTests {
    @Test func internetMessageDateInit() throws {
        #expect(try InternetMessageDate(internetMessageDate: "Tue, 28 Nov 2023 08:55:43 -0800") == InternetMessageDate(Date(timeIntervalSince1970: 1701190543.0), timeZone: TimeZone(secondsFromGMT: -8 * 3600)!))
        #expect(try InternetMessageDate(internetMessageDate: "Fri, 23 Jan 2026 13:23:47 +0000 (UTC)") == InternetMessageDate(Date(timeIntervalSince1970: 1769174627.0), timeZone: .gmt))
        #expect(try InternetMessageDate(internetMessageDate: "Tue, 28 Nov 2023 08:55:43-0500") == InternetMessageDate(Date(timeIntervalSince1970: 1701179743.0), timeZone: TimeZone(secondsFromGMT: -5 * 3600)!))
        #expect(try InternetMessageDate(internetMessageDate: "Tue, 28 Nov 2023 08:55:43+0700") == InternetMessageDate(Date(timeIntervalSince1970: 1701136543.0), timeZone: TimeZone(secondsFromGMT: 7 * 3600)!))
        #expect(try InternetMessageDate(internetMessageDate: "Sun, 25 Jan 2026 10:21:49 GMT") == InternetMessageDate(Date(timeIntervalSince1970: 1769336509.0), timeZone: .gmt))
    }
}

struct RFC822DateFormatterTests {
    @Test func string() {
        #expect(RFC822DateFormatter().string(from: InternetMessageDate(Date(timeIntervalSince1970: 1701190543.0), timeZone: TimeZone(secondsFromGMT: -8 * 3600)!)) == "Tue, 28 Nov 2023 08:55:43 -0800")
        #expect(RFC822DateFormatter().string(from: InternetMessageDate(Date(timeIntervalSince1970: 1769174627.0), timeZone: .gmt)) == "Fri, 23 Jan 2026 13:23:47 +0000")
        #expect(RFC822DateFormatter().string(from: InternetMessageDate(Date(timeIntervalSince1970: 1701179743.0), timeZone: TimeZone(secondsFromGMT: -5 * 3600)!)) == "Tue, 28 Nov 2023 08:55:43 -0500")
        #expect(RFC822DateFormatter().string(from: InternetMessageDate(Date(timeIntervalSince1970: 1701136543.0), timeZone: TimeZone(secondsFromGMT: 7 * 3600)!)) == "Tue, 28 Nov 2023 08:55:43 +0700")
        #expect(RFC822DateFormatter().string(from: InternetMessageDate(Date(timeIntervalSince1970: 1769336509.0), timeZone: .gmt)) == "Sun, 25 Jan 2026 10:21:49 +0000")
    }

    @Test func internetMessageDate() throws {
        #expect(try RFC822DateFormatter().internetMessageDate(from: "Tue, 28 Nov 2023 08:55:43 -0800") == InternetMessageDate(Date(timeIntervalSince1970: 1701190543.0), timeZone: TimeZone(secondsFromGMT: -8 * 3600)!))
        #expect(try RFC822DateFormatter().internetMessageDate(from: "Fri, 23 Jan 2026 13:23:47 +0000 (UTC)") == InternetMessageDate(Date(timeIntervalSince1970: 1769174627.0), timeZone: .gmt))
        #expect(try RFC822DateFormatter().internetMessageDate(from: "Tue, 28 Nov 2023 08:55:43-0500") == InternetMessageDate(Date(timeIntervalSince1970: 1701179743.0), timeZone: TimeZone(secondsFromGMT: -5 * 3600)!))
        #expect(try RFC822DateFormatter().internetMessageDate(from: "Tue, 28 Nov 2023 08:55:43+0700") == InternetMessageDate(Date(timeIntervalSince1970: 1701136543.0), timeZone: TimeZone(secondsFromGMT: 7 * 3600)!))
        #expect(try RFC822DateFormatter().internetMessageDate(from: "Sun, 25 Jan 2026 10:21:49 GMT") == InternetMessageDate(Date(timeIntervalSince1970: 1769336509.0), timeZone: .gmt))
    }
}

struct TimeZoneTests {
    @Test func internetMessageDateInit() throws {
        #expect(try TimeZone(internetMessageDate: "Tue, 28 Nov 2023 08:55:43 -0800") == TimeZone(secondsFromGMT: -8 * 3600))
        #expect(try TimeZone(internetMessageDate: "Fri, 23 Jan 2026 13:23:47 +0000 (UTC)") == .gmt)
        #expect(try TimeZone(internetMessageDate: "Tue, 28 Nov 2023 08:55:43-0500") == TimeZone(secondsFromGMT: -5 * 3600))
        #expect(try TimeZone(internetMessageDate: "Tue, 28 Nov 2023 08:55:43+0700") == TimeZone(secondsFromGMT: 7 * 3600))
        #expect(try TimeZone(internetMessageDate: "Sun, 25 Jan 2026 10:21:49 GMT") == .gmt)
    }
}
