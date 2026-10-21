// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI

struct AccountFolderDisclosureView: View {
    var account: Account
    var onSelect: (Folder) -> Void = { _ in }
    @Environment(MailboxModel.self) private var mailbox: MailboxModel
    @State private var isExpanded: Bool = false
    @State private var unreadCount: Int = 0

    private var folderManager: FolderManager {
        mailbox.folderManagers[account.id] ?? FolderManager(account: account)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(folderManager.folders) { folder in
                MailboxDropdownRowView(folder: folder, onSelect: onSelect)
            }
            .padding(.vertical, 10)
        } label: {
            HStack {
                AvatarView(
                    displayName: folderManager.account.name,
                    bubbleColor: Color(folderManager.account.avatarColor)
                )
                VStack(alignment: .leading) {
                    Text(account.name)
                        .font(.body)
                        .truncationMode(.middle)
                    if !account.name.isEmailAddress, let address: String = account.identities.first?.value {
                        Text(address)
                            .font(.caption)
                            .truncationMode(.middle)
                    }
                }.padding(.horizontal)
                    .foregroundStyle(.primary)
                Spacer()
                if !isExpanded && unreadCount > 0 {
                    UnreadCounter(unreadCount: unreadCount, hasNew: false)
                }
            }.padding(.vertical, 10)
                .safeAreaPadding(.horizontal)
        }.task {
            await mailbox.loadFolders(account: account)
            unreadCount = folderManager.folders.reduce(0) { $0 + ($1.unreadEmails ?? 0) }
        }.padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color.drawerCard)
            }
    }
}

#Preview {
    @Previewable @State var mailbox: MailboxModel = MailboxModel()

    AccountFolderDisclosureView(account: Account("temp@email.com"))
        .environment(mailbox)
}
