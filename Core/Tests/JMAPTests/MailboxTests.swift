// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import JMAP
import Testing

struct MailboxTests {

    // MARK: Decodable
    @Test func decoderInit() throws {
        let mailboxes: [Mailbox] = try JSONDecoder().decode([Mailbox].self, from: data)
        try #require(mailboxes.count == 6)
        #expect(mailboxes[0].name == "Inbox")
        #expect(mailboxes[0].role == .inbox)
        #expect(mailboxes[5].name == "Trash")
        #expect(mailboxes[5].role == .trash)
    }
}

extension MailboxTests {
    @Test func getMethod() throws {
        let ids: [String] = [
            "Me542737e24136513aaee4d41",
            "M56e3027f5b7cdfa3c2ce53ff"
        ]
        #expect(Mailbox.GetMethod.name == "Mailbox/get")
        #expect(try Mailbox.GetMethod("u7a5e4041").accountID == "u7a5e4041")
        #expect(try Mailbox.GetMethod("u7a5e4041", ids: ids).ids == ids)
        let dataWithIDs: Data = try JSONSerialization.data(withJSONObject: try Mailbox.GetMethod("u7a5e4041", ids: ids, id: id).object)
        guard let objectWithIDs: [Any] = try JSONSerialization.jsonObject(with: dataWithIDs) as? [Any], objectWithIDs.count == 3 else {
            throw URLError(.cannotDecodeContentData)
        }
        #expect(objectWithIDs[0] as? String == "Mailbox/get")
        #expect((objectWithIDs[1] as? [String: Any])?["accountId"] as? String == "u7a5e4041")
        #expect((objectWithIDs[1] as? [String: Any])?["ids"] as? [String] == ids)
        #expect(objectWithIDs[2] as? String == id.uuidString)
        let dataNoIDs: Data = try JSONSerialization.data(withJSONObject: try Mailbox.GetMethod("u7a5e4041", id: id).object)
        guard let objectNoIDs: [Any] = try JSONSerialization.jsonObject(with: dataNoIDs) as? [Any], objectNoIDs.count == 3 else {
            throw URLError(.cannotDecodeContentData)
        }
        #expect(objectNoIDs[0] as? String == "Mailbox/get")
        #expect((objectNoIDs[1] as? [String: Any])?["accountId"] as? String == "u7a5e4041")
        #expect((objectNoIDs[1] as? [String: Any])?["ids"] as? [String] == nil)
        #expect(objectNoIDs[2] as? String == id.uuidString)
        #expect(throws: MethodError.self) {
            try Mailbox.GetMethod("")
        }
    }

    @Test func setMethod() throws {
        #expect(Mailbox.SetMethod.name == "Mailbox/set")
        #expect(try Mailbox.SetMethod("u7a5e4041", actions: []).accountID == "u7a5e4041")
        #expect(
            try Mailbox.SetMethod(
                "u7a5e4041",
                actions: [
                    .destroy([
                        "Me542737e24136513aaee4d41"
                    ])
                ]
            ).actions.count == 1)
    }
}

extension MailboxTests {
    @Test func filterConditionObject() {
        #expect(Mailbox.Condition.parentId("M56e3027f5b7cdfa3c2ce53ff").object["parentId"] as? String == "M56e3027f5b7cdfa3c2ce53ff")
        #expect(Mailbox.Condition.name("Archived").object["name"] as? String == "Archived")
        #expect(Mailbox.Condition.role(.sent).object["role"] as? String == "sent")
        #expect(Mailbox.Condition.hasAnyRole(false).object["hasAnyRole"] as? Bool == false)
        #expect(Mailbox.Condition.isSubscribed(true).object["isSubscribed"] as? Bool == true)
    }

    @Test func filterConditionDescription() {
        #expect(Mailbox.Condition.parentId("M56e3027f5b7cdfa3c2ce53ff").description == "parentId: M56e3027f5b7cdfa3c2ce53ff")
        #expect(Mailbox.Condition.name("Archived").description == "name: Archived")
        #expect(Mailbox.Condition.role(.sent).description == "role: sent")
        #expect(Mailbox.Condition.hasAnyRole(false).description == "hasAnyRole: false")
        #expect(Mailbox.Condition.isSubscribed(true).description == "isSubscribed: true")
    }
}

private let id: UUID = UUID(uuidString: "AFF25F76-8105-413F-9CF7-F66B7703B8BD")!

// swift-format-ignore
private let data: Data = """
[
    {
        "totalEmails": 2,
        "myRights": {
            "maySubmit": true,
            "mayDelete": false,
            "mayReadItems": true,
            "mayAddItems": true,
            "mayAdmin": true,
            "maySetKeywords": true,
            "mayRename": false,
            "mayRemoveItems": true,
            "mayCreateChild": true,
            "maySetSeen": true
        },
        "unreadEmails": 0,
        "totalThreads": 2,
        "hidden": 0,
        "isCollapsed": false,
        "sort": [
            {
                "isAscending": false,
                "property": "receivedAt"
            }
        ],
        "sortOrder": 1,
        "name": "Inbox",
        "autoPurge": false,
        "id": "dc6a40aa-8657-4f74-9aaa-7046ca01325b",
        "autoLearn": false,
        "parentId": null,
        "suppressDuplicates": true,
        "isSubscribed": true,
        "role": "inbox",
        "identityRef": null,
        "purgeOlderThanDays": 31,
        "unreadThreads": 0,
        "learnAsSpam": false
    },
    {
        "totalEmails": 0,
        "myRights": {
            "mayCreateChild": true,
            "mayDelete": true,
            "mayReadItems": true,
            "mayAddItems": true,
            "mayAdmin": true,
            "maySetKeywords": true,
            "mayRename": true,
            "mayRemoveItems": true,
            "maySubmit": true,
            "maySetSeen": true
        },
        "unreadEmails": 0,
        "isCollapsed": false,
        "totalThreads": 0,
        "hidden": 0,
        "sort": [
            {
                "isAscending": false,
                "property": "receivedAt"
            }
        ],
        "sortOrder": 3,
        "name": "Archive",
        "autoPurge": false,
        "id": "f68852f4-f531-46f5-b279-1cfb09858476",
        "autoLearn": false,
        "parentId": null,
        "suppressDuplicates": true,
        "isSubscribed": true,
        "role": "archive",
        "identityRef": null,
        "unreadThreads": 0,
        "purgeOlderThanDays": 31,
        "learnAsSpam": false
    },
    {
        "totalEmails": 0,
        "myRights": {
            "mayRemoveItems": true,
            "mayDelete": true,
            "maySetSeen": true,
            "mayAddItems": true,
            "mayAdmin": true,
            "maySetKeywords": true,
            "mayRename": true,
            "mayReadItems": true,
            "maySubmit": true,
            "mayCreateChild": true
        },
        "unreadEmails": 0,
        "isCollapsed": false,
        "totalThreads": 0,
        "hidden": 0,
        "sort": [
            {
                "isAscending": false,
                "property": "receivedAt"
            }
        ],
        "sortOrder": 4,
        "name": "Drafts",
        "autoPurge": false,
        "id": "52fad03c-e7f0-4622-90f4-9d449bffd61c",
        "autoLearn": false,
        "parentId": null,
        "suppressDuplicates": true,
        "isSubscribed": true,
        "role": "drafts",
        "identityRef": null,
        "purgeOlderThanDays": 31,
        "unreadThreads": 0,
        "learnAsSpam": false
    },
    {
        "totalEmails": 0,
        "myRights": {
            "maySubmit": true,
            "mayDelete": true,
            "mayReadItems": true,
            "mayAddItems": true,
            "mayAdmin": true,
            "maySetKeywords": true,
            "mayRename": true,
            "mayRemoveItems": true,
            "mayCreateChild": true,
            "maySetSeen": true
        },
        "unreadEmails": 0,
        "totalThreads": 0,
        "hidden": 0,
        "isCollapsed": false,
        "sort": [
            {
                "isAscending": false,
                "property": "receivedAt"
            }
        ],
        "sortOrder": 5,
        "name": "Sent",
        "autoPurge": false,
        "id": "0faefa8a-8cfa-4562-be2a-a5d25381bbfa",
        "autoLearn": false,
        "parentId": null,
        "suppressDuplicates": true,
        "isSubscribed": true,
        "role": "sent",
        "identityRef": null,
        "purgeOlderThanDays": 31,
        "unreadThreads": 0,
        "learnAsSpam": false
    },
    {
        "totalEmails": 0,
        "myRights": {
            "maySubmit": true,
            "mayDelete": true,
            "mayCreateChild": true,
            "mayAddItems": true,
            "mayAdmin": true,
            "maySetKeywords": true,
            "mayRename": true,
            "mayRemoveItems": true,
            "mayReadItems": true,
            "maySetSeen": true
        },
        "unreadEmails": 0,
        "isCollapsed": false,
        "totalThreads": 0,
        "hidden": 0,
        "sort": [
            {
                "isAscending": false,
                "property": "receivedAt"
            }
        ],
        "sortOrder": 6,
        "name": "Spam",
        "autoPurge": true,
        "id": "22633599-d58d-4217-b0fb-28e2dd7cd723",
        "autoLearn": false,
        "parentId": null,
        "suppressDuplicates": true,
        "isSubscribed": true,
        "role": "junk",
        "identityRef": null,
        "purgeOlderThanDays": 31,
        "unreadThreads": 0,
        "learnAsSpam": false
    },
    {
        "totalEmails": 0,
        "myRights": {
            "maySubmit": true,
            "mayDelete": true,
            "mayReadItems": true,
            "mayAddItems": true,
            "mayAdmin": true,
            "maySetKeywords": true,
            "mayRename": true,
            "mayRemoveItems": true,
            "mayCreateChild": true,
            "maySetSeen": true
        },
        "unreadEmails": 0,
        "totalThreads": 0,
        "hidden": 0,
        "isCollapsed": false,
        "sort": [
            {
                "isAscending": false,
                "property": "receivedAt"
            }
        ],
        "sortOrder": 7,
        "name": "Trash",
        "autoPurge": true,
        "id": "115bb529-ea77-4af0-b726-c037cdf7cb86",
        "autoLearn": false,
        "parentId": null,
        "suppressDuplicates": true,
        "isSubscribed": true,
        "role": "trash",
        "identityRef": null,
        "unreadThreads": 0,
        "purgeOlderThanDays": 31,
        "learnAsSpam": false
    }
]
""".data(using: .utf8)!
