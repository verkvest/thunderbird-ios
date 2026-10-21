// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI
import Core

struct ComposeHeaderView: View {
    @State var email: Email?
    var draft: ComposeDraft? = nil

    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass: UserInterfaceSizeClass?
    @State private var subject: String = ""
    @State private var toRecipients: [String] = []
    @State private var replyToRecipients: [String] = []
    @State private var ccRecipients: [String] = []
    @State private var bccRecipients: [String] = []
    @State private var selectedSender: UUID = UUID()
    @State private var showCCBCC: Bool = false
    @State private var showReplyTo: Bool = false

    func populateFromEmail(_ email: Email?) {
        guard let email else { return }

        subject = email.subject ?? subject

        toRecipients = email.toStringArray
        replyToRecipients = email.replyToStringArray
        ccRecipients = email.ccStringArray
        bccRecipients = email.bccStringArray
    }

    var body: some View {
        VStack {
            Group {
                HStack {
                    Picker("from_header", selection: $selectedSender) {
                        ForEach(accountManager.allAccounts) { account in
                            Text(account.name).tag(account.id)
                        }
                    } currentValueLabel: {
                        Text(accountManager.account(for: selectedSender)?.name ?? "")
                    }
                    .pickerStyle(.menu)

                    Spacer()

                    VStack {
                        if !showReplyTo {
                            Spacer()
                            Button("", systemImage: "chevron.down") {
                                showReplyTo = true
                            }
                            .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }

                if showReplyTo {
                    MultiAddressBar("reply_to_header", $replyToRecipients)
                }

                HStack(alignment: .top) {
                    MultiAddressBar("to_header", $toRecipients)
                    if !showCCBCC {
                        VStack {
                            Spacer()
                            Button("", systemImage: "chevron.down") {
                                showCCBCC = true
                            }
                            .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
            }
            .padding(.bottom, 4)

            if showCCBCC {
                MultiAddressBar("cc_header", $ccRecipients)
                MultiAddressBar("bcc_header", $bccRecipients)
            }

            Divider()

            TextField("subject_header", text: $subject)
                .font(.body)
                .padding(horizontalSizeClass == .compact ? 8 : 12)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(horizontalSizeClass == .compact ? 8 : 16)
        .onAppear {
            populateFromEmail(email)
            if let draft, draft.accountID == nil {
                draft.accountID = accountManager.allAccounts.first?.id
            }
            if let id: UUID = draft?.accountID {
                selectedSender = id
            } else if let first: UUID = accountManager.allAccounts.first?.id {
                selectedSender = first
            }
            publish()
        }
        .onChange(of: subject) { publish() }
        .onChange(of: toRecipients) { publish() }
        .onChange(of: ccRecipients) { publish() }
        .onChange(of: bccRecipients) { publish() }
        .onChange(of: selectedSender) { publish() }
    }

    private func publish() {
        draft?.subject = subject
        draft?.to = toRecipients
        draft?.cc = ccRecipients
        draft?.bcc = bccRecipients
        draft?.accountID = selectedSender
    }
}

struct MultiAddressBar: View {
    init(
        _ header: LocalizedStringResource = "",
        _ entryText: Binding<[String]>,
    ) {
        headerText = header
        _entryText = entryText
    }

    private var headerText: LocalizedStringResource
    @Binding private var entryText: [String]
    @State private var entryString: String = ""

    // MARK: View
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(headerText)
                    .fixedSize()
                TextField("", text: $entryString)
                    .textFieldStyle(.automatic)
                    #if os(iOS)
                .autocapitalization(.none)
                    #endif
                    .autocorrectionDisabled()
                    .focusable()
                    .onSubmit {
                        if entryString.isEmailAddress {
                            entryText.append(entryString)
                            entryString = ""
                        }
                    }
            }
            HStackWrap {
                ForEach(entryText, id: \.self) { email in
                    EmailPill(email, $entryText)
                }
            }
        }
        .padding()
        .background(.gray, in: RoundedRectangle(cornerRadius: 24))
    }
}

struct EmailPill: View {
    init(_ email: String, _ currentEntries: Binding<[String]>) {
        emailAddress = email
        _entries = currentEntries
    }

    @State private var emailAddress: String
    @Binding private var entries: [String]

    var body: some View {
        HStack {
            Text(emailAddress)
                .fixedSize(horizontal: true, vertical: false)
            Label("remove_button", systemImage: "x.circle").labelStyle(.iconOnly)
                .onTapGesture {
                    entries.remove(at: entries.firstIndex(of: emailAddress)!)
                }
        }.padding(2)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.2))
                    .stroke(.gray, lineWidth: 1)
            }
    }
}

#Preview {
    @Previewable @State var accountManager: AccountManager = AccountManager()

    ComposeHeaderView()
        .environment(accountManager)
}
