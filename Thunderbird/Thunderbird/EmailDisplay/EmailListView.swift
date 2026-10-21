// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Bolt
import Core
import SwiftUI

struct EmailListView: View {
    @Environment(AccountManager.self) private var accountManager: AccountManager
    @Environment(MailboxModel.self) private var mailbox: MailboxModel
    @State private var path: NavigationPath = NavigationPath()
    @State private var selections: Set<String> = []
    @State private var showDrawer: Bool = false
    @State private var compose: ComposeDraft = ComposeDraft()

    private var accounts: [Account] { accountManager.allAccounts }

    // MARK: View
    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                List(selection: $selections) {
                    if let error: String = mailbox.errorMessage, mailbox.rows.isEmpty {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else if mailbox.rows.isEmpty {
                        Text(mailbox.isLoading ? "inbox_loading" : "inbox_empty")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    ForEach(mailbox.rows) { header in
                        NavigationLink(value: header.id) {
                            EmailCellView(header: header)
                        }
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await mailbox.delete(header, accounts: accounts) }
                            } label: {
                                Label("delete_button", systemImage: "trash")
                            }
                            Button {
                                Task { await mailbox.archive(header, accounts: accounts) }
                            } label: {
                                Label("archive_button", systemImage: "archivebox")
                            }
                            .tint(.indigo)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                Task { await mailbox.toggleRead(header, accounts: accounts) }
                            } label: {
                                Label(header.unread ? "mark_read_button" : "mark_unread_button", systemImage: header.unread ? "envelope.open" : "envelope.badge")
                            }
                            .tint(.blue)
                            Button {
                                Task { await mailbox.toggleFlag(header, accounts: accounts) }
                            } label: {
                                Label("flag_button", systemImage: header.flagged ? "flag.slash" : "flag")
                            }
                            .tint(.orange)
                        }
                        .onAppear {
                            guard header.id == mailbox.rows.last?.id else { return }
                            Task { await mailbox.loadMore(accounts: accounts) }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await mailbox.refresh(accounts: accounts)
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: mailbox.actionTick)

                Button {
                    compose = ComposeDraft()
                    compose.accountID = mailbox.selectedAccountID ?? accounts.first?.id
                    path.append("compose")
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                        .padding(14)
                        .background(.tint.opacity(0.15), in: Circle())
                }
                .padding()
                .accessibilityLabel("compose")
                DrawerView(showDrawer: $showDrawer)
            }
            .navigationTitle(LocalizedStringKey(mailbox.title(accounts: accounts)))
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .leading) {
                    Button {
                        showDrawer = true
                    } label: {
                        Label("accounts_heading", systemImage: "line.3.horizontal").labelStyle(.iconOnly)
                    }
                }
                ToolbarItem(placement: .trailing) {
                    Menu {
                        Button("unified_inbox") {
                            Task { await mailbox.select(accountID: nil, mailbox: "INBOX", accounts: accounts) }
                        }
                        ForEach(accounts) { account in
                            Button(account.name) {
                                Task { await mailbox.select(accountID: account.id, mailbox: "INBOX", accounts: accounts) }
                            }
                        }
                    } label: {
                        Image(systemName: "person.2")
                    }
                    .accessibilityLabel("unified_inbox")
                }
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "compose" {
                    ComposeView(draft: compose)
                } else if let header: MailCache.Header = mailbox.rows.first(where: { $0.id == destination }) {
                    ReadEmailView(header: header)
                }
            }
            .task {
                mailbox.showCache(accounts: accounts)
                await mailbox.refresh(accounts: accounts)
            }
        }
    }
}

private extension View {
    @ViewBuilder func navigationBarTitleDisplayModeInline() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

private extension ToolbarItemPlacement {
    static var leading: Self {
        #if os(iOS)
        .topBarLeading
        #else
        .automatic
        #endif
    }

    static var trailing: Self {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}
