// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Account
import Testing
import Foundation

struct DeletePolicyTests {
    @Test func rawValue() {
        #expect(DeletePolicy.after().rawValue == "after 7 days")
        #expect(DeletePolicy.after(days: 0).rawValue == "after 0 days")
        #expect(DeletePolicy.after(days: 3).rawValue == "after 3 days")
        #expect(DeletePolicy.onDelete.rawValue == "on delete")
        #expect(DeletePolicy.markAsRead.rawValue == "mark as read")
        #expect(DeletePolicy.never.rawValue == "never")
    }

    @Test func rawValueInit() {
        #expect(DeletePolicy(rawValue: "after 42796 days") == .after(days: 42796))
        #expect(DeletePolicy(rawValue: "after 0 days") == .after(days: 0))
        #expect(DeletePolicy(rawValue: "after 3 days") == .after(days: 3))
        #expect(DeletePolicy(rawValue: "after 7 days") == .after())
        #expect(DeletePolicy(rawValue: "7 days") == nil)
        #expect(DeletePolicy(rawValue: "-1 days") == nil)
        #expect(DeletePolicy(rawValue: "after7days") == nil)
        #expect(DeletePolicy(rawValue: "on delete") == .onDelete)
        #expect(DeletePolicy(rawValue: "delete") == nil)
        #expect(DeletePolicy(rawValue: "mark as read") == .markAsRead)
        #expect(DeletePolicy(rawValue: "markAsRead") == nil)
        #expect(DeletePolicy(rawValue: "never") == .never)
        #expect(DeletePolicy(rawValue: "nevar") == nil)
    }
}
