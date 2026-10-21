// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Foundation
import Observation

@MainActor
@Observable
final class ComposeDraft {
    var accountID: UUID?
    var to: [String] = []
    var cc: [String] = []
    var bcc: [String] = []
    var subject: String = ""
    var html: String = ""
    var seed: Email?

    func apply(_ email: Email?, accountID: UUID?) {
        seed = email
        self.accountID = accountID
        subject = email?.subject ?? ""
        to = email?.toStringArray ?? []
        cc = email?.ccStringArray ?? []
        bcc = email?.bccStringArray ?? []
        html = email?.body?.html() ?? email?.body?.text ?? ""
    }
}

extension String {
    var strippingTags: String {
        replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
