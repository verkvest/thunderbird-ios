// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import EmailAddress
import Foundation
@testable import JMAP
import Testing

struct EmailTests {
    @Test func decoderInit() throws {
        let emails: [Email] = try JSONDecoder(date: .iso8601).decode([Email].self, from: data)
        try #require(emails.count == 2)
        #expect(emails[0].blobID == "G8a183cc18aec2b46bd7b7f11c81d65783d400482")
        #expect(emails[0].threadID == "T1bebe52081852054")
        #expect(
            emails[0].mailboxIDs == [
                "dc6a40aa-8657-4f74-9aaa-7046ca01325b": true
            ])
        #expect(
            emails[0].keywords == [
                "$answered": true,
                "$seen": true,
                "$hasattachment": true,
                "$x-me-annot-2": true
            ])
        #expect(emails[0].size == 272443)
        #expect(emails[0].receivedAt == Date(timeIntervalSince1970: 1751057580.0))
        #expect(emails[0].sentAt == Date(timeIntervalSince1970: 1751057565.0))
        #expect(
            emails[0].messageID == [
                "104F9518-F8FD-4C84-9491-6A887D865DCC@me.com"
            ])
        #expect(emails[0].inReplyTo == nil)
        #expect(emails[0].references == nil)
        #expect(emails[0].sender == nil)
        #expect(
            emails[0].from?.first?.addresses == [
                EmailAddress("user@example.com", label: "Example User")
            ])
        #expect(emails[0].replyTo == nil)
        #expect(
            emails[0].to?.first?.addresses == [
                EmailAddress("recipient@example.com")
            ])
        #expect(emails[0].cc == nil)
        #expect(emails[0].bcc == nil)
        #expect(emails[0].subject == "Test email")
        #expect(
            emails[0].textBody == [
                Email.BodyPart(
                    size: 34212,
                    type: "text/html",
                    charset: "UTF-8"
                )
            ])
        #expect(
            emails[0].htmlBody == [
                Email.BodyPart(
                    size: 34212,
                    type: "text/html",
                    charset: "UTF-8"
                )
            ])
        #expect(
            emails[0].attachments == [
                Email.BodyPart(
                    size: 192428,
                    name: "test-invoice.zip",
                    type: "application/zip",
                    disposition: "attachment"
                )
            ])
        #expect(emails[0].hasAttachment == true)
        #expect(emails[0].preview == "Your full invoice is attached to this email. Amount paid Payment method $6.00 (inc. tax) Individual Jun 27, 2025 9:00 pm UTC - Jul 27, 2025 9:00 pm UTC")

        #expect(emails[1].blobID == "Gd80606e8b5e8b03eba586b5febbdf57b75183d6e")
        #expect(emails[1].threadID == "T1bebe52081852054")
        #expect(
            emails[1].mailboxIDs == [
                "0faefa8a-8cfa-4562-be2a-a5d25381bbfa": true
            ])
        #expect(
            emails[1].keywords == [
                "$seen": true,
                "$x-me-annot-2": true
            ])
        #expect(emails[1].size == 1244)
        #expect(emails[1].receivedAt == Date(timeIntervalSince1970: 1751123625.0))
        #expect(emails[1].sentAt == Date(timeIntervalSince1970: 1751123625.0))
        #expect(
            emails[1].messageID == [
                "b2143c4d-f3ed-451d-b4ad-d6951641598d@app.fastmail.com"
            ])
        #expect(
            emails[1].inReplyTo == [
                "104F9518-F8FD-4C84-9491-6A887D865DCC@me.com"
            ])
        #expect(
            emails[1].references == [
                "104F9518-F8FD-4C84-9491-6A887D865DCC@me.com"
            ])
        #expect(emails[1].sender == nil)
        #expect(
            emails[1].from?.first?.addresses == [
                EmailAddress("recipient@example.com", label: "Example User")
            ])
        #expect(emails[1].replyTo == nil)
        #expect(
            emails[1].to?.first?.addresses == [
                EmailAddress("user@example.com", label: "Example User")
            ])
        #expect(emails[1].cc == nil)
        #expect(emails[1].bcc == nil)
        #expect(emails[1].subject == "Re: Test")
        #expect(
            emails[1].textBody == [
                Email.BodyPart(
                    size: 144,
                    type: "text/plain",
                    charset: "UTF-8"
                )
            ])
        #expect(
            emails[1].htmlBody == [
                Email.BodyPart(
                    size: 332,
                    type: "text/html",
                    charset: "UTF-8"
                )
            ])
        #expect(emails[1].attachments == [])
        #expect(emails[1].hasAttachment == false)
        #expect(emails[1].preview == "This is a test. On Fri, Jun 27, 2025, at 4:52 PM, Example User wrote:")
    }

    @Test func filterConditionObject() {
        let date: Date = Date(timeIntervalSince1970: 0.0)
        #expect(Email.Condition.inMailbox("M56e3027f5b7cdfa3c2ce53ff").object["inMailbox"] as? String == "M56e3027f5b7cdfa3c2ce53ff")
        #expect(
            Email.Condition.inMailboxOtherThan([
                "M56e3027f5b7cdfa3c2ce53ff",
                "Me542737e24136513aaee4d41"
            ]).object["inMailboxOtherThan"] as? [String] == [
                "M56e3027f5b7cdfa3c2ce53ff",
                "Me542737e24136513aaee4d41"
            ])
        #expect(Email.Condition.before(date).object["before"] as? String == "1970-01-01T00:00:00Z")
        #expect(Email.Condition.maxSize(5_242_880).object["maxSize"] as? Int == 5_242_880)
        #expect(Email.Condition.allInThreadHaveKeyword("$important").object["allInThreadHaveKeyword"] as? String == "$important")
        #expect(Email.Condition.hasAttachment(true).object["hasAttachment"] as? Bool == true)
    }

    @Test func filterConditionDescription() {
        #expect(Email.Condition.inMailbox("M56e3027f5b7cdfa3c2ce53ff").description == "inMailbox: M56e3027f5b7cdfa3c2ce53ff")
        #expect(
            Email.Condition.inMailboxOtherThan([
                "M56e3027f5b7cdfa3c2ce53ff",
                "Me542737e24136513aaee4d41"
            ]).description == "inMailboxOtherThan: [\"M56e3027f5b7cdfa3c2ce53ff\", \"Me542737e24136513aaee4d41\"]")
        #expect(Email.Condition.after(Date(timeIntervalSince1970: 0.0)).description == "after: 1970-01-01T00:00:00Z")
        #expect(Email.Condition.minSize(1024).description == "minSize: 1024")
        #expect(Email.Condition.noneInThreadHaveKeyword("$important").description == "noneInThreadHaveKeyword: $important")
        #expect(Email.Condition.hasAttachment(true).description == "hasAttachment: true")
    }
}

// swift-format-ignore
private let data: Data = """
[
    {
        "threadId": "T1bebe52081852054",
        "inReplyTo": null,
        "preview": "Your full invoice is attached to this email. Amount paid Payment method $6.00 (inc. tax) Individual Jun 27, 2025 9:00 pm UTC - Jul 27, 2025 9:00 pm UTC",
        "blobId": "G8a183cc18aec2b46bd7b7f11c81d65783d400482",
        "textBody": [
            {
                "blobId": "Ge29e799be812d61f901ddc554ebe7745da2703cc",
                "partId": "1",
                "location": null,
                "charset": "UTF-8",
                "disposition": null,
                "size": 34212,
                "language": null,
                "type": "text/html",
                "name": null,
                "cid": null
            }
        ],
        "bcc": null,
        "sentAt": "2025-06-27T16:52:45-04:00",
        "subject": "Test email",
        "keywords": {
            "$answered": true,
            "$seen": true,
            "$hasattachment": true,
            "$x-me-annot-2": true
        },
        "cc": null,
        "mailboxIds": {
            "dc6a40aa-8657-4f74-9aaa-7046ca01325b": true
        },
        "replyTo": null,
        "hasAttachment": true,
        "htmlBody": [
            {
                "partId": "1",
                "blobId": "Ge29e799be812d61f901ddc554ebe7745da2703cc",
                "location": null,
                "charset": "UTF-8",
                "disposition": null,
                "size": 34212,
                "language": null,
                "type": "text/html",
                "name": null,
                "cid": null
            }
        ],
        "id": "M8a183cc18aec2b46bd7b7f11",
        "messageId": [
            "104F9518-F8FD-4C84-9491-6A887D865DCC@me.com"
        ],
        "size": 272443,
        "to": [
            {
                "email": "recipient@example.com",
                "name": null
            }
        ],
        "attachments": [
            {
                "partId": "1",
                "blobId": "Gd1d973a81058fbd90d16918d75a941fa1d9c262f",
                "location": null,
                "charset": null,
                "disposition": "attachment",
                "size": 192428,
                "language": null,
                "type": "application/zip",
                "name": "test-invoice.zip",
                "cid": null
            }
        ],
        "sender": null,
        "from": [
            {
                "email": "user@example.com",
                "name": "Example User"
            }
        ],
        "references": null,
        "receivedAt": "2025-06-27T20:53:00Z",
        "bodyValues": {

        }
    },
    {
        "threadId": "T1bebe52081852054",
        "inReplyTo": [
            "104F9518-F8FD-4C84-9491-6A887D865DCC@me.com"
        ],
        "preview": "This is a test. On Fri, Jun 27, 2025, at 4:52 PM, Example User wrote:",
        "blobId": "Gd80606e8b5e8b03eba586b5febbdf57b75183d6e",
        "textBody": [
            {
                "partId": "1",
                "blobId": "G961fff2a35fd69ad74313cfdb1883769d38857e7",
                "location": null,
                "charset": "utf-8",
                "disposition": null,
                "size": 144,
                "language": null,
                "type": "text/plain",
                "name": null,
                "cid": null
            }
        ],
        "bcc": null,
        "sentAt": "2025-06-28T11:13:45-04:00",
        "subject": "Re: Test",
        "keywords": {
            "$seen": true,
            "$x-me-annot-2": true
        },
        "cc": null,
        "mailboxIds": {
            "0faefa8a-8cfa-4562-be2a-a5d25381bbfa": true
        },
        "size": 1244,
        "hasAttachment": false,
        "messageId": [
            "b2143c4d-f3ed-451d-b4ad-d6951641598d@app.fastmail.com"
        ],
        "id": "Md80606e8b5e8b03eba586b5f",
        "htmlBody": [
            {
                "partId": "2",
                "blobId": "G6076f35db56ef3522d50ac3140e75e5ba5bc9b84",
                "location": null,
                "charset": "us-ascii",
                "disposition": null,
                "size": 332,
                "language": null,
                "type": "text/html",
                "name": null,
                "cid": null
            }
        ],
        "replyTo": null,
        "to": [
            {
                "name": "Example User",
                "email": "user@example.com"
            }
        ],
        "attachments": [

        ],
        "sender": null,
        "from": [
            {
                "name": "Example User",
                "email": "recipient@example.com"
            }
        ],
        "receivedAt": "2025-06-28T15:13:45Z",
        "references": [
            "104F9518-F8FD-4C84-9491-6A887D865DCC@me.com"
        ],
        "bodyValues": {

        }
    }
]
""".data(using: .utf8)!
