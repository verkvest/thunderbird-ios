// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration

extension [EmailProvider.Server.Authentication] {
    func joined(separator: String = "") -> String {
        map { $0.description }.joined(separator: separator)
    }
}
