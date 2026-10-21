// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LocalAuthentication
import SwiftUI

@MainActor
@Observable
final class AppLock {
    var isLocked: Bool = false
    var failed: Bool = false

    func lockIfNeeded() {
        guard UserDefaults.standard.bool(forKey: "verkvest.faceIDLock") else {
            isLocked = false
            return
        }
        isLocked = true
        failed = false
    }

    func unlock() async {
        let context: LAContext = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            failed = true
            return
        }
        do {
            let ok: Bool = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: NSLocalizedString("face_id_reason", comment: ""))
            isLocked = !ok
            failed = !ok
        } catch {
            failed = true
        }
    }
}

struct LockScreen: View {
    @Environment(AppLock.self) private var lock: AppLock

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
            Text("face_id_locked")
                .font(.title2)
                .multilineTextAlignment(.center)
            if lock.failed {
                Text("face_id_failed")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("face_id_unlock") {
                Task { await lock.unlock() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .task { await lock.unlock() }
    }
}
