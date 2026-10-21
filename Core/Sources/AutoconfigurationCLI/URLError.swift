// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URLError: @retroactive CustomStringConvertible {

    // MARK:  CustomStringConvertible
    public var description: String {
        switch code {
        case .fileDoesNotExist: "File not found"
        case .unsupportedURL: "Unsupported URL"
        case .notConnectedToInternet: "Not connected to internet"
        default: localizedDescription
        }
    }
}
