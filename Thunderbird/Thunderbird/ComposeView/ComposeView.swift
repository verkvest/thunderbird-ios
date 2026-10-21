// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Core
import SwiftUI

struct ComposeView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(\.dismiss) private var dismiss: DismissAction
    @State var draft: ComposeDraft
    @State private var isSending: Bool = false
    @State private var errorMessage: String?

    init(draft: ComposeDraft = ComposeDraft()) {
        _draft = State(initialValue: draft)
    }

    init(email: Email?) {
        let draft: ComposeDraft = ComposeDraft()
        draft.apply(email, accountID: nil)
        _draft = State(initialValue: draft)
    }

    var body: some View {
        EmailBodyView(email: draft.seed, draft: draft, editable: true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close_button") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("send_button") {
                        Task { await send() }
                    }
                    .disabled(isSending || draft.to.isEmpty)
                }
            }
            .alert("send_failed", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("close_button", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
    }

    private func send() async {
        let account: Account? = draft.accountID.flatMap { accountManager.account(for: $0) } ?? accountManager.allAccounts.first
        guard let account else {
            errorMessage = "account_missing"
            return
        }
        isSending = true
        defer { isSending = false }
        let html: Bool = draft.html.contains("<")
        let body: String = html ? draft.html : draft.html.strippingTags
        do {
            try await account.send(to: draft.to, cc: draft.cc, bcc: draft.bcc, subject: draft.subject, body: body, html: html)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
