import Account
import Testing

extension Server: CaseIterable {

    // MARK: Fastmail
    static var fastmail: Self {
        Self(
            .jmap,
            connectionSecurity: .tls,
            username: "example@fastmail.com",
            hostname: "api.fastmail.com"
        )
    }

    // MARK: Gmail
    static var gmail: Self {
        Self(
            .imap,
            connectionSecurity: .tls,
            authenticationType: .password,
            username: "example@thunderbird.net",
            hostname: "imap.gmail.com"
        )
    }

    // MARK: CaseIterable
    public static let allCases: [Self] = [.fastmail, .gmail]
}
