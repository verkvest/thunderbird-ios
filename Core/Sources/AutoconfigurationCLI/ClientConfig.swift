// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Autoconfiguration
#if canImport(Cocoa)
import Cocoa
#endif
import Foundation

extension ClientConfig {
    func openDocumentation() throws {
        guard let urls: [URL] = emailProvider?.documentation else {
            throw URLError(.resourceUnavailable)
        }
        for url in urls {
            open(url)
        }
    }

    func openWebMailLoginPage() throws {
        guard let url: URL = webMail?.loginPage else {
            throw URLError(.resourceUnavailable)
        }
        open(url)
    }
}

// swift-format-ignore
private func open(_ url: URL) {
#if canImport(Cocoa)
    NSWorkspace.shared.open(url)
#endif
}
