// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import JMAP
import Testing

struct LocaleTests {
    @Test func acceptedLanguages() {
        #expect(Locale.acceptedLanguages().hasPrefix(Locale.preferredLanguages.first ?? "*"))
        #expect(Locale.acceptedLanguages().hasSuffix("*;q=0.5"))
    }
}
