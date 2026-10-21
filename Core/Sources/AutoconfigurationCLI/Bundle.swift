// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(Cocoa)
import Cocoa
#endif
import Foundation

// swift-format-ignore
extension Bundle {
    var executableDirectory: URL { executableURL!.deletingLastPathComponent() }

    func showExecutableInFinder() {
#if canImport(Cocoa)
        NSWorkspace.shared.open(executableDirectory)
#endif
    }
}
