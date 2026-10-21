@testable import Account
import Testing
import Foundation

struct MailboxPathTests {
    @Test func suggestedRole() throws {
        #expect(try IMAP.Mailbox.Path(name: "INBOX").suggestedRole == .inbox)
        #expect(try IMAP.Mailbox.Path(name: "[Gmail]/Inbox", pathSeparator: "/").suggestedRole == .inbox)
        #expect(try IMAP.Mailbox.Path(name: "Sent Mail").suggestedRole == .sent)
        #expect(try IMAP.Mailbox.Path(name: "Deleted Items").suggestedRole == .trash)
        #expect(try IMAP.Mailbox.Path(name: "junk mail").suggestedRole == .junk)
        #expect(try IMAP.Mailbox.Path(name: "Spam").suggestedRole == .junk)
        #expect(try IMAP.Mailbox.Path(name: "Trash").suggestedRole == .trash)
        #expect(try IMAP.Mailbox.Path(name: "drafts").suggestedRole == .drafts)
        #expect(try IMAP.Mailbox.Path(name: "Draft").suggestedRole == .drafts)
    }
}
